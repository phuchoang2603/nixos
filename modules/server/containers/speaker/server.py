"""Hermes' speaker: music from Felix's Jellyfin library and speech, on the speaker plugged into pve.

Audio goes to PULSE_SERVER, the PipeWire sink in the "audio" LXC on pve (CT 120). mpv holds the
music queue; speech is synthesised with Piper and played over the music, which ducks meanwhile.
"""

import asyncio
import itertools
import json
import os
import random
import socket
import subprocess
import tempfile
import threading
import time
import wave
from urllib.parse import urlencode

import httpx
from mcp.server.mcpserver import MCPServer
from piper import PiperVoice

JELLYFIN = os.environ["JELLYFIN_URL"].rstrip("/")
JELLYFIN_KEY = os.environ["JELLYFIN_API_KEY"]
VOICE = os.environ["PIPER_VOICE"]
SOCKET = "/tmp/mpv.sock"
MUSIC_VOLUME = 60
DUCK = 0.3

mcp = MCPServer(
    "speaker",
    instructions="Felix's speaker at home: play music from his Jellyfin library and speak text out loud.",
)

# Stream URLs carry the API key, so they're never shown: tools report these titles instead.
titles: dict[str, str] = {}
_request_ids = itertools.count(1)
_speech = threading.Lock()
_voice: PiperVoice | None = None
_user_id = ""
_http = httpx.Client(
    base_url=JELLYFIN,
    headers={"Authorization": f'MediaBrowser Token="{JELLYFIN_KEY}"'},
    timeout=20,
)


def keep_mpv() -> None:
    while True:
        subprocess.run(
            [
                "mpv",
                "--idle=yes",
                "--no-video",
                "--no-terminal",
                "--ytdl=no",
                "--ao=pulse",
                "--audio-client-name=Hermes music",
                f"--input-ipc-server={SOCKET}",
                f"--volume={MUSIC_VOLUME}",
                "--volume-max=100",
                "--prefetch-playlist=yes",
            ]
        )
        time.sleep(2)


def mpv(*command):
    request_id = next(_request_ids)
    for attempt in range(20):
        try:
            conn = socket.socket(socket.AF_UNIX)
            conn.settimeout(15)
            conn.connect(SOCKET)
            break
        except OSError:
            conn.close()
            if attempt == 19:
                raise RuntimeError("the music player isn't running")
            time.sleep(0.25)
    with conn:
        conn.sendall(json.dumps({"command": list(command), "request_id": request_id}).encode() + b"\n")
        buf = b""
        while True:
            chunk = conn.recv(65536)
            if not chunk:
                raise RuntimeError("the music player closed the connection")
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                msg = json.loads(line)
                if msg.get("request_id") != request_id:
                    continue
                if msg.get("error") != "success":
                    raise RuntimeError(f"mpv {command[0]}: {msg.get('error')}")
                return msg.get("data")


def prop(name: str, default=None):
    try:
        value = mpv("get_property", name)
    except RuntimeError:
        return default
    return default if value is None else value


def fade(start: float, end: float, seconds: float) -> None:
    steps = max(1, int(seconds * 5))
    for i in range(1, steps + 1):
        mpv("set_property", "volume", round(start + (end - start) * i / steps, 1))
        time.sleep(seconds / steps)


def clock(seconds) -> str:
    seconds = int(seconds or 0)
    return f"{seconds // 60}:{seconds % 60:02d}"


def jf(path: str, **params):
    try:
        r = _http.get(path, params={k: v for k, v in params.items() if v is not None})
    except httpx.TransportError as e:
        raise RuntimeError(f"Jellyfin is unreachable ({type(e).__name__})") from None
    if r.status_code == 401:
        raise RuntimeError("Jellyfin rejected the speaker's API key")
    r.raise_for_status()
    return r.json()


def items(**params) -> list[dict]:
    global _user_id
    if not _user_id:
        admins = [u for u in jf("/Users") if u.get("Policy", {}).get("IsAdministrator")]
        if not admins:
            raise RuntimeError("no Jellyfin user to play as")
        _user_id = admins[0]["Id"]
    return jf("/Items", userId=_user_id, recursive=True, **params)["Items"]


def songs(what: str) -> list[dict]:
    if what.strip().casefold() in ("", "everything", "all", "anything"):
        return items(includeItemTypes="Audio", sortBy="Random", limit=300)
    hits = items(searchTerm=what, includeItemTypes="Playlist,MusicArtist,MusicAlbum,Audio", limit=20)
    pick = next(
        (h for h in hits if h["Type"] != "Audio" and h["Name"].casefold() == what.strip().casefold()), None
    ) or next((h for h in hits if h["Type"] == "Audio"), None) or (hits[0] if hits else None)
    if not pick:
        return []
    order = "ParentIndexNumber,IndexNumber,SortName"
    match pick["Type"]:
        case "Audio":
            return [pick]
        case "MusicArtist":
            return items(artistIds=pick["Id"], includeItemTypes="Audio", sortBy=f"Album,{order}")
        case _:
            return items(parentId=pick["Id"], includeItemTypes="Audio", sortBy=order)


def play_songs(what: str, shuffle: bool, append: bool) -> str:
    found = songs(what)
    if not found:
        return f"Nothing in the library matches {what!r}."
    if shuffle:
        random.shuffle(found)
    start = not append or prop("idle-active", True)
    for i, song in enumerate(found):
        url = f"{JELLYFIN}/Audio/{song['Id']}/stream?{urlencode({'static': 'true', 'ApiKey': JELLYFIN_KEY})}"
        artists = ", ".join(song.get("Artists") or [])
        titles[url] = f"{song['Name']} - {artists}" if artists else song["Name"]
        mpv("loadfile", url, "replace" if start and i == 0 else "append-play")
    mpv("set_property", "pause", False)
    first = titles[url] if len(found) == 1 else f"{len(found)} songs"
    return f"{'Playing' if start else 'Queued'} {first}."


def say_text(text: str) -> None:
    global _voice
    with _speech:
        if _voice is None:
            _voice = PiperVoice.load(VOICE)
        with tempfile.NamedTemporaryFile(suffix=".wav", dir="/tmp") as f:
            with wave.open(f.name, "wb") as out:
                _voice.synthesize_wav(text, out)
            music = not prop("idle-active", True) and not prop("pause", True)
            volume = prop("volume", MUSIC_VOLUME)
            if music:
                fade(volume, volume * DUCK, 0.6)
            try:
                # The sink is suspended when idle; the delay keeps the first word from being clipped.
                subprocess.run(
                    [
                        "mpv",
                        "--no-video",
                        "--no-terminal",
                        "--ao=pulse",
                        "--audio-client-name=Hermes voice",
                        "--af=lavfi=[adelay=delays=400:all=1]",
                        f.name,
                    ],
                    timeout=600,
                )
            finally:
                if music:
                    fade(volume * DUCK, volume, 1.0)


@mcp.tool()
async def play(what: str = "everything", shuffle: bool = False, append: bool = False) -> str:
    """Play music from Felix's library: an artist, album, song or playlist name, or
    "everything" for the whole library shuffled. append adds it after the current queue
    instead of replacing it."""
    return await asyncio.to_thread(play_songs, what, shuffle, append)


@mcp.tool()
async def control(action: str) -> str:
    """Control playback: "pause", "resume", "next", "previous" or "stop"."""
    commands = {
        "pause": ("set_property", "pause", True),
        "resume": ("set_property", "pause", False),
        "next": ("playlist-next", "force"),
        "previous": ("playlist-prev", "force"),
        "stop": ("stop",),
    }
    if action not in commands:
        return f"Unknown action {action!r}; use one of {', '.join(commands)}."
    await asyncio.to_thread(mpv, *commands[action])
    return f"Done: {action}."


@mcp.tool()
async def volume(level: int) -> str:
    """Set the music volume, 0-100."""
    await asyncio.to_thread(mpv, "set_property", "volume", max(0, min(100, level)))
    return f"Volume {max(0, min(100, level))}."


@mcp.tool()
async def status() -> dict:
    """What's playing, its position, the volume and how many songs are queued after it."""

    def run():
        queue = prop("playlist", [])
        pos = prop("playlist-pos", -1)
        playing = None
        if not prop("idle-active", True) and pos >= 0:
            playing = {
                "title": titles.get(queue[pos]["filename"], "unknown"),
                "position": f"{clock(prop('time-pos'))} / {clock(prop('duration'))}",
                "paused": prop("pause", False),
            }
        return {
            "now_playing": playing,
            "volume": round(prop("volume", MUSIC_VOLUME)),
            "queued_after_this": max(0, len(queue) - pos - 1),
        }

    return await asyncio.to_thread(run)


@mcp.tool()
async def say(text: str) -> str:
    """Speak text out loud in English. Music keeps playing, quieter, underneath.
    Keep it short and written for the ear: no markdown, links or long lists."""
    await asyncio.to_thread(say_text, text)
    return "Spoken."


if __name__ == "__main__":
    threading.Thread(target=keep_mpv, daemon=True).start()
    mcp.run(transport="streamable-http", host="0.0.0.0", port=8000, stateless_http=True)
