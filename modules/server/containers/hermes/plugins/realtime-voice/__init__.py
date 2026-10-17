"""Full-duplex Discord voice through an OpenAI Realtime model, with Hermes as the backend.

The realtime model owns the conversation (turn-taking, barge-in, speech). It speaks as Hermes
(SOUL.md and the skills index make up its instructions) and calls Hermes' own tools in
process, MCP gateway included, with the same toolsets and approval rules as an API server turn.
Long or multi-step work goes to the full Hermes agent through ask_hermes and its OpenAI-compatible
API server, which also owns memory and session search. When a call ends, its transcript is
retained in Hindsight, the same memory bank the agent recalls from.

Audio receive reuses the Discord adapter's ``VoiceReceiver`` (transport + DAVE decryption, Opus
decode); this plugin only drains its per-participant PCM buffers. Everything else touching Hermes
internals is confined to ``_adapter`` and ``_receiver_cls``.
"""

from __future__ import annotations

import array
import asyncio
import base64
import json
import logging
import os
import re
import sys
import threading
import time
from collections import deque
from contextlib import suppress
from datetime import datetime, timezone

import aiohttp
import discord
import websockets

logger = logging.getLogger(__name__)

REALTIME_URL = os.getenv("REALTIME_VOICE_URL", "ws://cli-proxy-api:8317/v1/realtime")
MODEL = os.getenv("REALTIME_VOICE_MODEL", "gpt-realtime-2")
VOICE = os.getenv("REALTIME_VOICE_VOICE", "marin")
AUTO_JOIN = os.getenv("REALTIME_VOICE_AUTO_JOIN", "true").lower() in ("1", "true", "yes")
HERMES_API = os.getenv("REALTIME_VOICE_HERMES_API", "http://127.0.0.1:8642")
# Text channel that gets one audit thread per call; unset posts into the voice channel's chat.
LOG_CHANNEL = int(os.getenv("REALTIME_VOICE_LOG_CHANNEL", "0") or 0)
# Seconds between spoken progress updates while Hermes works; 0 turns them off.
PROGRESS_INTERVAL = float(os.getenv("REALTIME_VOICE_PROGRESS_INTERVAL", "15") or 0)

# discord.AudioSource.read() must return 20 ms of 48 kHz stereo s16le.
FRAME_BYTES = 3840
# Input is streamed in fixed ticks (silence included) so server-side VAD can see pauses.
TICK = 0.04
SILENCE = base64.b64encode(bytes(int(24000 * TICK) * 2)).decode()

VOICE_NOTE = """## Live voice call

You are talking with Felix in a Discord voice channel. Speak naturally and briefly, like a person
on a call, and stop talking when interrupted. Everything you say is heard, not read: no markdown,
lists, code, or URLs.

Handle anything that takes one to a few tool calls yourself; don't hand it off. The gmail_*,
calendar_* and tasks_* functions call those integrations directly, so reading his email,
calendar or tasks, and adding a task are all yours. For any other integration listed below, call
mcp__executor__search with its integration, owner and connection plus a few words for the action,
then mcp__executor__invoke with the returned id and arguments. Never guess a result; wait for the
tool. Before a call that may take more than a moment, say in a few words what you're doing.

Use ask_hermes, which hands the request to the full Hermes agent, only when:
- the task takes many steps, research across several sources, or more than a minute;
- it needs the terminal, the browser, files, or skill edits;
- a skill you loaded needs a tool you don't have;
- something should be remembered, or he refers to past conversations (only the agent has memory
  and session search);
- a tool says it needs approval or was blocked.
The agent cannot hear the call, so put everything it needs into the request."""

# Used when the Hermes context can't be built; ask_hermes still reaches everything.
FALLBACK_INSTRUCTIONS = (
    "You are Hermes, Felix's personal assistant, talking with him in a Discord voice channel. "
    "Speak naturally and briefly, like a person on a call, and stop talking when interrupted.\n\n"
    "Your one tool, ask_hermes, reaches the Hermes agent. It can run commands on the homelab, "
    "search the web, read and change files, use Felix's integrations, and it remembers past "
    "sessions. Call it whenever Felix asks for facts, current information, or for anything to be "
    "done, checked or remembered. Do not call it for small talk or to repeat something already "
    "said. Before calling it, say in a few words that you are checking. Never guess a result; "
    "wait for the tool. The agent cannot hear the call, so put everything it needs into the "
    "request."
)

# Direct tool calls run as an API server turn under this key: same toolsets, and approvals resolve
# on their own (smart or deny) instead of waiting for a click nobody can give mid-call.
TOOL_SESSION = "realtime-voice"
# The quick-turn subset of Hermes' tools. Everything else goes through ask_hermes, which keeps
# those schemas out of the voice session.
VOICE_TOOLS = {"web_search", "skill_view", "mcp__executor__search", "mcp__executor__invoke"}

# MCP gateway tools the voice model gets as plain functions: (tool id, parameters to keep).
# None keeps them all; "a.b" keeps field b of object parameter a. Google's APIs list a dozen
# transport parameters on every call, which would otherwise dominate the session.
EXECUTOR_TOOLS = {
    "gmail_list_messages": ("tools.google_gmail.user.xuanphucA1gv.gmail.users.messages.list",
                            ["userId", "q", "maxResults", "labelIds"]),
    "gmail_get_message": ("tools.google_gmail.user.xuanphucA1gv.gmail.users.messages.get",
                          ["userId", "id", "format", "metadataHeaders"]),
    "calendar_list_calendars": ("tools.google_calendar.user.personalGoogleCalendarApi.calendar.calendarList.list", []),
    "calendar_list_events": ("tools.google_calendar.user.personalGoogleCalendarApi.calendar.events.list",
                             ["calendarId", "timeMin", "timeMax", "q", "singleEvents", "orderBy", "maxResults"]),
    "tasks_list_tasklists": ("tools.google_tasks.user.personalGoogleTasksApi.tasks.tasklists.list", []),
    "tasks_list_tasks": ("tools.google_tasks.user.personalGoogleTasksApi.tasks.tasks.list",
                         ["tasklist", "showCompleted", "dueMin", "dueMax", "maxResults"]),
    "tasks_insert_task": ("tools.google_tasks.user.personalGoogleTasksApi.tasks.tasks.insert",
                          ["tasklist", "body.title", "body.notes", "body.due"]),
}
MAX_TOOL_OUTPUT = 16000

TURN_NOTE = (
    "[This request comes from a live voice call and your reply will be spoken aloud by a voice "
    "model. Answer in a few plain conversational sentences: no markdown, lists, code or URLs. Do "
    "the work with your tools as usual and do not claim an action succeeded before it did.]"
)

# The API server inlines MEDIA: images as base64 data URLs, which must not reach the voice model.
_INLINE_IMAGE = re.compile(r"!\[[^\]]*\]\(data:image/[^)]+\)")
_DATA_URL = re.compile(r"data:[\w/+.-]+;base64,[A-Za-z0-9+/=]+")

PROGRESS_INSTRUCTIONS = (
    "The Hermes agent is still working on a task for Felix. Tell him in one short spoken sentence "
    "(under 15 words) what it is doing right now, based on its latest actions below. Paraphrase "
    "plainly: no commands, paths or tool names. Do not claim it is finished and do not ask questions."
)

SESSION = {
    "type": "realtime",
    "output_modalities": ["audio"],
    "audio": {
        "input": {
            "format": {"type": "audio/pcm", "rate": 24000},
            "transcription": {"model": "gpt-4o-mini-transcribe"},
            "turn_detection": {"type": "semantic_vad"},
        },
        "output": {"format": {"type": "audio/pcm", "rate": 24000}, "voice": VOICE},
    },
    "tool_choice": "auto",
}

ASK_HERMES = {
    "type": "function",
    "name": "ask_hermes",
    "description": "Delegate a request to the full Hermes agent and get its answer.",
    "parameters": {
        "type": "object",
        "properties": {"request": {"type": "string", "description": "What Hermes should do or answer, with all needed context."}},
        "required": ["request"],
    },
}


def _sentence(text: str, limit: int = 160) -> str:
    text = " ".join(text.split())
    end = text.find(". ")
    if 0 < end < limit:
        return text[:end + 1]
    return text if len(text) <= limit else text[:limit] + "…"


def _shorten(node, in_properties: bool = False):
    """Drop schema titles and keep property descriptions to a sentence."""
    if isinstance(node, list):
        return [_shorten(n) for n in node]
    if not isinstance(node, dict):
        return node
    out = {}
    for key, value in node.items():
        if in_properties:
            out[key] = _shorten(value)
        elif key not in ("title", "$schema", "additionalProperties"):
            out[key] = _sentence(value) if key == "description" and isinstance(value, str) else _shorten(value, key == "properties")
    return out


def _prune(schema: dict, keep, defs: dict | None = None) -> dict:
    schema = _shorten(schema)
    if keep is None:
        return schema
    defs = schema.get("$defs", {}) if defs is None else defs
    props, wanted = schema.get("properties") or {}, {}
    for path in keep:
        name, _, field = path.partition(".")
        if name in props:
            wanted.setdefault(name, []).extend([field] if field else [])
    kept = {}
    for name, fields in wanted.items():
        prop = props[name]
        if fields and "$ref" in prop:
            prop = defs.get(prop["$ref"].rsplit("/", 1)[-1], prop)
        kept[name] = _prune(prop, fields, defs) if fields and "properties" in prop else prop
    pruned = {**{k: v for k, v in schema.items() if k not in ("properties", "required", "$defs")},
              "properties": kept, "required": [r for r in schema.get("required", []) if r in kept]}
    if "$defs" in schema and '"$ref"' in json.dumps(kept):
        pruned["$defs"] = schema["$defs"]
    return pruned


def _executor_result(output: str):
    data = json.loads(output)
    return json.loads(data["result"]) if isinstance(data.get("result"), str) else data


def _integration_text(output: str) -> str:
    """An integration call's result without the MCP envelope or its structured duplicate."""
    with suppress(Exception):
        result = _executor_result(output)
        if isinstance(result, dict) and isinstance(result.get("content"), list):
            texts = [c.get("text", "") for c in result["content"] if c.get("type") == "text"]
            if texts:
                return "\n".join(texts)
        return json.dumps(result, ensure_ascii=False, separators=(",", ":"))
    return output


def _executor_context(enabled: list, disabled: list) -> dict:
    """Plain functions for EXECUTOR_TOOLS and a list of connected integrations, as Executor has them now."""
    tools, ids = [], {}
    for name, (tool_id, keep) in EXECUTOR_TOOLS.items():
        _, integration, owner, connection, *action = tool_id.split(".")
        try:
            found = _executor_result(_run_hermes_tool("mcp__executor__search", {
                "integration": integration, "owner": owner, "connection": connection, "query": " ".join(action)},
                enabled, disabled))
            item = next(i for i in found.get("items", []) if i.get("id") == tool_id)
        except Exception as e:
            logger.warning("Voice tool %s unavailable: %s", name, e)
            continue
        parameters = _prune(item.get("inputSchema") or {}, keep)
        parameters["type"] = "object"
        parameters.setdefault("properties", {})
        description = " ".join((item.get("description") or name).split())[:500]
        tools.append({"type": "function", "name": name, "description": description, "parameters": parameters})
        ids[name] = tool_id
    integrations = ""
    with suppress(Exception):
        items = _executor_result(_run_hermes_tool("mcp__executor__integrations", {}, enabled, disabled)).get("items", [])
        integrations = "\n".join(f"- {i['integrationName']}: integration {i['integration']}, owner {i['owner']}, "
                                 f"connection {i['connection']}" for i in items)
    return {"tools": tools, "ids": ids, "integrations": integrations}


def _hermes_context() -> dict:
    """Instructions, realtime tools and how to run them, read fresh per connection."""
    import model_tools
    from agent.prompt_builder import build_skills_system_prompt, load_soul_md
    from hermes_cli.config import load_config
    from hermes_cli.tools_config import _get_platform_tools
    from hermes_constants import get_hermes_home
    from tools.registry import registry

    config = load_config()
    enabled = sorted(_get_platform_tools(config, "api_server"))
    disabled = list((config.get("agent") or {}).get("disabled_toolsets") or [])
    # The tool-definition cache records its last answer as the process-wide execute_code default.
    previous = list(model_tools._last_resolved_tool_names)
    try:
        defs = model_tools.get_tool_definitions(enabled_toolsets=enabled, disabled_toolsets=disabled, quiet_mode=True)
    finally:
        model_tools._last_resolved_tool_names = previous
    available = {d["function"]["name"] for d in defs}
    # MCP tools sit behind the tool-search bridge, so their schemas come from the registry.
    schemas = [d["function"] for d in defs] + [e.schema for n in VOICE_TOOLS if n not in available
                                               for e in [registry.get_entry(n)] if e is not None]
    tools = [{"type": "function", "name": f["name"], "description": f.get("description", ""),
              "parameters": _shorten(f.get("parameters") or {"type": "object", "properties": {}})}
             for f in schemas if f["name"] in VOICE_TOOLS]
    executor = _executor_context(enabled, disabled)

    parts = [load_soul_md() or "You are Hermes, Felix's personal assistant."]
    # Names only, without the main agent's skill-maintenance preamble.
    skills = get_hermes_home() / "skills"
    categories = frozenset(p.name for p in skills.iterdir() if p.is_dir() and not p.name.startswith(".")) if skills.is_dir() else frozenset()
    index = re.search(r"<available_skills>\n(.*?)\n</available_skills>", build_skills_system_prompt(
        available_tools=available, available_toolsets=set(enabled), compact_categories=categories), re.S)
    if index:
        parts.append("## Skills\n\nHermes' skills by category. Load one with skill_view(name) when it fits.\n"
                     + index.group(1).replace(" [names only]", ""))
    if executor["integrations"]:
        parts.append("## Integrations in the MCP gateway\n\n" + executor["integrations"])
    parts.append(VOICE_NOTE)
    parts.append(time.strftime("It is now %A, %B %d, %Y, %H:%M (%Z, UTC%z)."))
    return {"instructions": "\n\n".join(p.strip() for p in parts if p),
            "tools": [*tools, *executor["tools"], ASK_HERMES],
            "toolsets": (enabled, disabled), "executor_ids": executor["ids"]}


def _run_hermes_tool(name: str, args: dict, enabled: list, disabled: list) -> str:
    import model_tools
    from gateway.session_context import clear_session_vars, set_session_vars

    tokens = set_session_vars(platform="api_server", session_key=TOOL_SESSION, async_delivery=False, cron_session="")
    try:
        return model_tools.handle_function_call(name, args, task_id=TOOL_SESSION, session_id=TOOL_SESSION,
                                                enabled_toolsets=enabled, disabled_toolsets=disabled)
    finally:
        clear_session_vars(tokens)


def _tool_failed(output: str) -> bool:
    with suppress(ValueError):
        data = json.loads(output)
        return isinstance(data, dict) and bool(data.get("error"))
    return False


def _for_voice(output: str) -> str:
    output = _DATA_URL.sub("[binary omitted]", _INLINE_IMAGE.sub("[image omitted]", output))
    return output if len(output) <= MAX_TOOL_OUTPUT else output[:MAX_TOOL_OUTPUT] + "…[truncated]"


def _downsample(pcm: bytes) -> array.array:
    """48 kHz stereo -> 24 kHz mono."""
    s = array.array("h")
    s.frombytes(pcm[: len(pcm) // 8 * 8])
    return array.array("h", ((a + b + c + d) >> 2 for a, b, c, d in zip(s[0::4], s[1::4], s[2::4], s[3::4])))


def _upsample(pcm: bytes) -> bytes:
    """24 kHz mono -> 48 kHz stereo."""
    s = array.array("h")
    s.frombytes(pcm[: len(pcm) // 2 * 2])
    out = array.array("h", bytes(len(s) * 8))
    for i in range(4):
        out[i::4] = s
    return out.tobytes()


def _mix(tracks: list) -> array.array:
    if len(tracks) == 1:
        return tracks[0]
    out = array.array("h", bytes(2 * max(map(len, tracks))))
    for track in tracks:
        for i, v in enumerate(track):
            out[i] = max(-32768, min(32767, out[i] + v))
    return out


def _chunks(text: str, size: int = 1900) -> list:
    """Split into Discord-sized messages, preferring line breaks."""
    out, current = [], ""
    for line in text.splitlines():
        for piece in [line[i:i + size] for i in range(0, len(line), size)] or [""]:
            if current and len(current) + len(piece) + 1 > size:
                out.append(current)
                current = piece
            else:
                current = f"{current}\n{piece}" if current else piece
    if current:
        out.append(current)
    return out


def _describe_tool_call(call: dict) -> str:
    fn = call.get("function") or {}
    try:
        args = json.loads(fn.get("arguments") or "{}")
    except ValueError:
        args = fn.get("arguments")
    detail = args.get("command") if isinstance(args, dict) and "command" in args else json.dumps(args, ensure_ascii=False)
    detail = str(detail).replace("`", "'")
    if len(detail) > 300:
        detail = detail[:300] + "…"
    return f"🔧 `{fn.get('name', '?')}` `{detail}`"


async def _sse(resp):
    """Yield ``(event, data)`` from a server-sent event stream; ``event`` is "" for plain chunks."""
    event = ""
    async for raw in resp.content:
        line = raw.decode("utf-8", "replace").rstrip("\r\n")
        if line.startswith("event:"):
            event = line[6:].strip()
        elif line.startswith("data:"):
            data = line[5:].strip()
            if data == "[DONE]":
                return
            with suppress(ValueError):
                yield event, json.loads(data)
        elif not line:
            event = ""


def _api_key() -> str:
    key = os.getenv("API_SERVER_KEY", "")
    if not key:
        with suppress(Exception):
            from hermes_cli.config import get_env_value
            key = get_env_value("API_SERVER_KEY") or ""
    return key


async def _retain_call(spoken: list, started: float) -> None:
    """Hand the call's transcript to Hindsight, where the agent's own conversations go."""
    if not spoken:
        return
    try:
        from hermes_constants import get_hermes_home
        config = json.loads((get_hermes_home() / "hindsight" / "config.json").read_text(encoding="utf-8"))
        item = {
            "content": json.dumps(spoken, ensure_ascii=False),
            "timestamp": datetime.fromtimestamp(started, timezone.utc).isoformat(),
            "context": "Discord voice call between Felix and Hermes, his personal agent",
            "document_id": f"voice-call-{int(started)}",
            "metadata": {"source": config.get("retain_source") or "hermes", "platform": "discord-voice"},
        }
        if config.get("observation_scopes"):
            item["observation_scopes"] = config["observation_scopes"]
        url = f"{config['api_url'].rstrip('/')}/v1/default/banks/{config['bank_id']}/memories"
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30)) as http:
            async with http.post(url, json={"items": [item], "async": True}) as resp:
                if resp.status >= 400:
                    raise RuntimeError(f"HTTP {resp.status}: {(await resp.text())[:200]}")
        logger.info("Realtime voice retained %d spoken turns in Hindsight", len(spoken))
    except Exception as e:
        logger.warning("Realtime voice could not retain the call in Hindsight: %s", e)


def _adapter():
    """The live Discord adapter of the running gateway, or None outside the gateway."""
    run = sys.modules.get("gateway.run")
    runner = run._gateway_runner_ref() if run else None
    if runner is None:
        return None
    return next((a for p, a in runner.adapters.items() if getattr(p, "value", p) == "discord"), None)


def _receiver_cls(adapter):
    base = sys.modules[type(adapter).__module__].VoiceReceiver

    class StreamingReceiver(base):
        def drain(self) -> list:
            """Take everything decoded so far as ``[(user_id, pcm48_stereo)]``."""
            with self._lock:
                chunks = [(self._ssrc_to_user.get(ssrc, 0), bytes(buf)) for ssrc, buf in self._buffers.items() if buf]
                for buf in self._buffers.values():
                    buf.clear()
            return chunks

    return StreamingReceiver


class _Playback(discord.AudioSource):
    """Realtime audio queued for Discord; pads short gaps so jittery deltas don't stop playback."""

    GRACE_FRAMES = 15

    def __init__(self):
        self._buf = bytearray()
        self._lock = threading.Lock()
        self._idle = 0

    def feed(self, pcm: bytes) -> None:
        with self._lock:
            self._buf.extend(pcm)
            self._idle = 0

    def clear(self) -> None:
        with self._lock:
            self._buf.clear()

    def read(self) -> bytes:
        with self._lock:
            if self._buf:
                frame = bytes(self._buf[:FRAME_BYTES])
                del self._buf[:FRAME_BYTES]
                return frame.ljust(FRAME_BYTES, b"\0")
            self._idle += 1
            return b"" if self._idle > self.GRACE_FRAMES else bytes(FRAME_BYTES)

    def is_opus(self) -> bool:
        return False


class _Call:
    def __init__(self, vc, receiver, allowed: set):
        self.vc = vc
        self.receiver = receiver
        self.allowed = allowed
        self.playback = _Playback()
        self.ws = None
        self.tasks: list = []
        self.closed = False
        self.responding = False
        self.response_pending = False
        self.active_response = None
        self.user_speaking = False
        self.session_id = ""
        self.toolsets: tuple = ([], [])
        self.executor_ids: dict = {}
        self.open_calls = 0
        self.transcript: deque = deque(maxlen=12)
        self.spoken: list = []
        self.started = time.time()
        self.audit_target = None
        self.audit_lock = asyncio.Lock()

    async def start(self) -> None:
        self.tasks = [asyncio.create_task(self._run_realtime()), asyncio.create_task(self._pump())]

    async def stop(self) -> None:
        self.closed = True
        for task in self.tasks:
            task.cancel()
        await _retain_call(self.spoken, self.started)
        if self.audit_target is not None:
            minutes = max(1, round((time.time() - self.started) / 60))
            await self._audit(f"📴 Call ended after {minutes} min.")
        if self.ws is not None:
            with suppress(Exception):
                await self.ws.close()
        self.receiver.stop()
        if self.vc.is_connected():
            await self.vc.disconnect(force=True)

    async def _send(self, event: dict) -> None:
        ws = self.ws
        if ws is not None:
            with suppress(Exception):
                await ws.send(json.dumps(event))

    async def _session(self) -> dict:
        try:
            context = await asyncio.to_thread(_hermes_context)
            instructions, tools = context["instructions"], context["tools"]
            self.toolsets, self.executor_ids = context["toolsets"], context["executor_ids"]
        except Exception:
            logger.exception("Realtime voice could not load Hermes' context; only ask_hermes is available")
            instructions, tools = FALLBACK_INSTRUCTIONS, [ASK_HERMES]
        return {**SESSION, "instructions": instructions, "tools": tools}

    async def _run_realtime(self) -> None:
        backoff = 1
        while not self.closed:
            try:
                session = await self._session()
                async with websockets.connect(
                    f"{REALTIME_URL}?model={MODEL}", max_size=None,
                    additional_headers={"Authorization": "Bearer realtime-voice"},
                ) as ws:
                    self.ws = ws
                    self.responding = self.response_pending = self.user_speaking = False
                    self.active_response = None
                    self.open_calls = 0
                    await ws.send(json.dumps({"type": "session.update", "session": session}))
                    logger.info("Realtime voice connected (%s, %d tools)", MODEL, len(session["tools"]))
                    backoff = 1
                    async for raw in ws:
                        await self._on_event(json.loads(raw))
            except asyncio.CancelledError:
                raise
            except Exception as e:
                logger.warning("Realtime voice connection dropped: %s", e)
            self.ws = None
            if not self.closed:
                await asyncio.sleep(backoff)
                backoff = min(backoff * 2, 30)

    def _accepts(self, user_id: int) -> bool:
        if user_id:
            return str(user_id) in self.allowed
        # An SSRC not yet mapped to a user is only trusted when everyone present is allowed.
        channel = self.vc.channel
        return bool(channel) and all(str(m.id) in self.allowed for m in channel.members if not m.bot)

    async def _pump(self) -> None:
        while not self.closed:
            await asyncio.sleep(TICK)
            tracks = [_downsample(pcm) for user_id, pcm in self.receiver.drain() if self._accepts(user_id)]
            audio = base64.b64encode(_mix(tracks).tobytes()).decode() if tracks else SILENCE
            await self._send({"type": "input_audio_buffer.append", "audio": audio})

    async def _on_event(self, event: dict) -> None:
        kind = event.get("type", "")
        if kind in ("response.output_audio.delta", "response.audio.delta"):
            self.playback.feed(_upsample(base64.b64decode(event["delta"])))
            if self.vc.is_connected() and not self.vc.is_playing():
                self.vc.play(self.playback)
        elif kind == "input_audio_buffer.speech_started":
            self.user_speaking = True
            self.playback.clear()
        elif kind == "input_audio_buffer.speech_stopped":
            self.user_speaking = False
        elif kind == "response.created":
            self.responding = True
            self.active_response = event.get("response", {}).get("id")
        elif kind == "response.done":
            self.responding = False
            self.active_response = None
            if self.response_pending and self.open_calls == 0:
                await self._create_response()
        elif kind == "conversation.item.input_audio_transcription.completed":
            self._heard("user", "Felix", event.get("transcript", ""))
        elif kind in ("response.output_audio_transcript.done", "response.audio_transcript.done"):
            self._heard("assistant", "Hermes", event.get("transcript", ""))
        elif kind == "response.function_call_arguments.done":
            name, call_id, arguments = event.get("name", ""), event["call_id"], event.get("arguments") or "{}"
            run = self._ask_hermes(call_id, arguments) if name == "ask_hermes" else self._run_tool(call_id, name, arguments)
            self.open_calls += 1
            self.tasks = [t for t in self.tasks if not t.done()]
            self.tasks.append(asyncio.create_task(run))
        elif kind == "error":
            # A rejected response.create never gets a response.created to clear it.
            if self.active_response is None:
                self.responding = False
            logger.warning("Realtime voice error: %s", event.get("error"))

    def _heard(self, role: str, who: str, text: str) -> None:
        text = text.strip()
        if text:
            self.transcript.append(f"{who}: {text}")
            self.spoken.append({"role": role, "content": f"{who}: {text}",
                                "timestamp": datetime.now(timezone.utc).isoformat()})

    async def _create_response(self, response: dict | None = None) -> bool:
        """Start a response unless one is running; a deferred conversation reply runs after it."""
        if self.responding:
            if response is None:
                self.response_pending = True
            return False
        self.responding = True
        if response is None:
            self.response_pending = False
        await self._send({"type": "response.create", **({"response": response} if response else {})})
        return True

    async def _narrate(self, request: str, actions: list) -> None:
        """Speak a short out-of-band update whenever Hermes has taken new actions."""
        told = 0
        while True:
            await asyncio.sleep(PROGRESS_INTERVAL)
            if len(actions) == told or self.user_speaking:
                continue
            latest = "\n".join(f"- {a}" for a in actions[told:][-4:])
            if await self._create_response({
                "conversation": "none",
                "output_modalities": ["audio"],
                "tools": [],
                "tool_choice": "none",
                "instructions": PROGRESS_INSTRUCTIONS,
                "input": [{"type": "message", "role": "user", "content": [
                    {"type": "input_text", "text": f"Task: {request}\nLatest actions:\n{latest}"}]}],
            }):
                told = len(actions)

    async def _ask_hermes(self, call_id: str, arguments: str) -> None:
        try:
            request = json.loads(arguments).get("request", "")
        except ValueError:
            request = arguments
        context = "\n".join(self.transcript)
        content = f"{TURN_NOTE}\n[Recent spoken conversation, newest last:\n{context}]\n\n{request}"
        headers = {"Authorization": f"Bearer {_api_key()}"}
        if self.session_id:
            headers["X-Hermes-Session-Id"] = self.session_id
        started, ok = time.time(), True
        actions: list = []
        narrator = asyncio.create_task(self._narrate(request, actions)) if PROGRESS_INTERVAL > 0 else None
        try:
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=900)) as http:
                async with http.post(
                    f"{HERMES_API}/v1/chat/completions", headers=headers,
                    json={"model": "hermes-agent", "stream": True,
                          "messages": [{"role": "user", "content": content}]},
                ) as resp:
                    if resp.status != 200:
                        raise RuntimeError(f"HTTP {resp.status}: {await resp.text()}")
                    self.session_id = resp.headers.get("X-Hermes-Session-Id", self.session_id)
                    parts = []
                    async for event, data in _sse(resp):
                        if event == "hermes.tool.progress" and data.get("status") == "running":
                            actions.append(f"{data.get('tool')}: {data.get('label')}")
                        elif not event:
                            parts.append((data.get("choices") or [{}])[0].get("delta", {}).get("content") or "")
                    output = _INLINE_IMAGE.sub("[image omitted]", "".join(parts)).strip()
                    if not output:
                        raise RuntimeError("the agent returned no answer")
        except Exception as e:
            logger.warning("ask_hermes failed: %s", e)
            ok, output = False, f"The Hermes agent could not complete this: {e}"
        finally:
            if narrator is not None:
                narrator.cancel()
        await self._tool_output(call_id, output)

        tools = await self._tool_calls_since(started) if ok else []
        lines = [f"🎙️ **Request** ({time.time() - started:.0f}s)", *(f"> {l}" for l in request.splitlines()), *tools,
                 f"{'✅' if ok else '❌'} **Hermes:** {output}"]
        if self.session_id:
            lines.append(f"-# session `{self.session_id}`")
        await self._audit("\n".join(lines))

    async def _run_tool(self, call_id: str, name: str, arguments: str) -> None:
        started = time.time()
        try:
            args = json.loads(arguments)
        except ValueError:
            args = {}
        args = args if isinstance(args, dict) else {}
        tool_id = self.executor_ids.get(name)
        try:
            if tool_id:
                output = await asyncio.to_thread(_run_hermes_tool, "mcp__executor__invoke",
                                                 {"tool": tool_id, "arguments": args}, *self.toolsets)
            else:
                output = await asyncio.to_thread(_run_hermes_tool, name, args, *self.toolsets)
        except Exception as e:
            logger.warning("Voice tool %s failed: %s", name, e)
            output = json.dumps({"error": f"{name} failed: {e}"})
        await self._tool_output(call_id, _for_voice(_integration_text(output) if tool_id else output))
        mark = "❌" if _tool_failed(output) else "✅"
        call = {"function": {"name": name, "arguments": arguments}}
        await self._audit(f"{_describe_tool_call(call)} {mark} ({time.time() - started:.1f}s)")

    async def _tool_output(self, call_id: str, output: str) -> None:
        """Hand a result back; the model answers once every call of its turn has one."""
        await self._send({"type": "conversation.item.create",
                          "item": {"type": "function_call_output", "call_id": call_id, "output": output}})
        self.open_calls = max(0, self.open_calls - 1)
        if self.open_calls == 0:
            await self._create_response()

    async def _tool_calls_since(self, since: float) -> list:
        try:
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=15)) as http:
                async with http.get(f"{HERMES_API}/api/sessions/{self.session_id}/messages",
                                    headers={"Authorization": f"Bearer {_api_key()}"}) as resp:
                    messages = (await resp.json(content_type=None)).get("data", [])
        except Exception as e:
            logger.warning("Could not read Hermes session tools: %s", e)
            return []
        messages = sorted((m for m in messages if float(m.get("timestamp") or 0) >= since),
                          key=lambda m: float(m["timestamp"]))
        calls = [c for m in messages if isinstance(m.get("tool_calls"), list) for c in m["tool_calls"]]
        return [_describe_tool_call(c) for c in calls]

    async def _audit(self, text: str) -> None:
        """Post to this call's audit thread, creating it on first use; never breaks the call."""
        async with self.audit_lock:
            try:
                if self.audit_target is None:
                    channel = self.vc.channel.guild.get_channel(LOG_CHANNEL) if LOG_CHANNEL else None
                    if channel is None:
                        self.audit_target = self.vc.channel
                    else:
                        name = time.strftime("🎙️ Voice call · %b %d %H:%M", time.localtime(self.started))
                        self.audit_target = await channel.create_thread(
                            name=name, type=discord.ChannelType.public_thread, auto_archive_duration=1440)
                for chunk in _chunks(text):
                    await self.audit_target.send(chunk, silent=True, allowed_mentions=discord.AllowedMentions.none())
            except Exception as e:
                logger.warning("Voice audit post failed: %s", e)


_calls: dict = {}
_join_lock: asyncio.Lock | None = None


def _owner_voice_channel(adapter):
    for guild in adapter._client.guilds:
        for user_id in adapter._allowed_user_ids:
            member = guild.get_member(int(user_id)) if str(user_id).isdigit() else None
            if member and member.voice and member.voice.channel:
                return member.voice.channel
    return None


async def _join(adapter, channel) -> str:
    global _join_lock
    _join_lock = _join_lock or asyncio.Lock()
    async with _join_lock:
        guild = channel.guild
        call = _calls.get(guild.id)
        if call and not call.closed:
            if call.vc.channel and call.vc.channel.id == channel.id:
                return f"Already live in {channel.name}."
            await call.stop()
        # Hand over from Hermes' own chained voice session if one is running.
        if guild.id in getattr(adapter, "_voice_clients", {}):
            await adapter.leave_voice_channel(guild.id)
        if guild.voice_client is not None:
            await guild.voice_client.disconnect(force=True)
        vc = await channel.connect()
        receiver = _receiver_cls(adapter)(vc, allowed_user_ids=adapter._allowed_user_ids)
        receiver.start()
        call = _Call(vc, receiver, {str(u) for u in adapter._allowed_user_ids})
        _calls[guild.id] = call
        await call.start()
        logger.info("Realtime voice joined %s", channel.name)
        return f"Live in {channel.name}."


async def _leave(guild_id: int) -> str:
    call = _calls.pop(guild_id, None)
    if call is None:
        return "Not in a voice call."
    await call.stop()
    return "Left the voice call."


async def _on_voice_state(member, before, after) -> None:
    adapter = _adapter()
    if adapter is None or member.bot:
        return
    try:
        call = _calls.get(member.guild.id)
        if call and call.vc.channel in (before.channel, after.channel):
            # Membership changes bump the DAVE epoch.
            call.receiver.refresh_credentials("membership change")
        allowed = {str(u) for u in adapter._allowed_user_ids}
        if not AUTO_JOIN or str(member.id) not in allowed:
            return
        if after.channel and after.channel != before.channel:
            await _join(adapter, after.channel)
        elif before.channel and not after.channel and call and call.vc.channel == before.channel:
            if not any(str(m.id) in allowed for m in before.channel.members if not m.bot):
                await _leave(member.guild.id)
    except Exception:
        logger.exception("Realtime voice auto-join failed")


async def _on_client_loop(make_coro):
    adapter = _adapter()
    if adapter is None or adapter._client is None:
        return "Discord is not connected."
    loop = adapter._client.loop
    if asyncio.get_running_loop() is loop:
        return await make_coro(adapter)
    return await asyncio.wrap_future(asyncio.run_coroutine_threadsafe(make_coro(adapter), loop))


async def _cmd_call(_args: str = "") -> str:
    async def run(adapter):
        channel = _owner_voice_channel(adapter)
        return await _join(adapter, channel) if channel else "Join a voice channel first."
    return await _on_client_loop(run)


async def _cmd_hangup(_args: str = "") -> str:
    async def run(_adapter):
        results = [await _leave(guild_id) for guild_id in list(_calls)]
        return results[0] if results else "Not in a voice call."
    return await _on_client_loop(run)


def _attach(client) -> None:
    client.add_listener(_on_voice_state, "on_voice_state_update")
    adapter = _adapter()
    channel = _owner_voice_channel(adapter) if AUTO_JOIN and adapter else None
    if channel is not None:
        asyncio.ensure_future(_join(adapter, channel))


def _watch_gateway() -> None:
    """Attach to every Discord client the gateway creates (it rebuilds one on reconnect)."""
    attached = None
    while True:
        time.sleep(3)
        with suppress(Exception):
            adapter = _adapter()
            client = getattr(adapter, "_client", None)
            if client is not None and client is not attached and client.is_ready():
                client.loop.call_soon_threadsafe(_attach, client)
                attached = client
                logger.info("Realtime voice attached to Discord")


def register(ctx) -> None:
    ctx.register_command("call", _cmd_call, description="Start a live voice call in your voice channel")
    ctx.register_command("hangup", _cmd_hangup, description="End the live voice call")
    # Plugins can be loaded more than once per process; a second watcher would join twice.
    if not any(t.name == "realtime-voice" for t in threading.enumerate()):
        threading.Thread(target=_watch_gateway, name="realtime-voice", daemon=True).start()
