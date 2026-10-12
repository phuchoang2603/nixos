"""Hermes' speaker tools: music through Jellyfin, speech through Piper.

Music plays on the "Speaker" device in Jellyfin (the speaker-player container, Jellyfin MPV Shim),
which these tools drive through Jellyfin's remote-control API, so Jellyfin shows what's playing and
counts the plays. Speech is synthesised here and played straight to the PipeWire sink at
PULSE_SERVER, with the music turned down underneath.
"""

import asyncio
import io
import os
import random
import subprocess
import tempfile
import threading
import wave

import httpx
from mcp.server.mcpserver import MCPServer
from piper import PiperVoice

PLAYER = os.environ.get("SPEAKER_PLAYER", "Speaker")
VOICE = os.environ["PIPER_VOICE"]
DUCK = 0.3
# Item ids go in the query string; batches keep it under the server's request-line limit.
BATCH = 100
COMMANDS = {"now": "PlayNow", "next": "PlayNext", "last": "PlayLast", "mix": "PlayInstantMix"}

mcp = MCPServer(
    "speaker",
    instructions="Felix's speaker at home: play music from his Jellyfin library and speak text out loud.",
)
jellyfin = httpx.Client(
    base_url=os.environ["JELLYFIN_URL"],
    headers={"Authorization": f'MediaBrowser Token="{os.environ["JELLYFIN_API_KEY"]}"'},
    timeout=20,
)
_speech = threading.Lock()
_voice: PiperVoice | None = None
_user_id = ""


def call(method: str, path: str, **kwargs):
    try:
        r = jellyfin.request(method, path, **kwargs)
    except httpx.TransportError as e:
        raise RuntimeError(f"Jellyfin is unreachable ({type(e).__name__})") from None
    if r.status_code == 401:
        raise RuntimeError("Jellyfin rejected the speaker's API key")
    r.raise_for_status()
    return r.json() if r.content else None


def session() -> dict:
    found = [s for s in call("GET", "/Sessions") if s.get("DeviceName") == PLAYER and s.get("SupportsRemoteControl")]
    if not found:
        raise RuntimeError(f'The "{PLAYER}" player isn\'t connected to Jellyfin')
    return max(found, key=lambda s: s.get("LastActivityDate") or "")


def items(**params) -> list[dict]:
    global _user_id
    if not _user_id:
        admins = [u for u in call("GET", "/Users") if u.get("Policy", {}).get("IsAdministrator")]
        _user_id = admins[0]["Id"]
    return call("GET", "/Items", params={"userId": _user_id, "recursive": True, **params})["Items"]


def find(query: str) -> list[dict]:
    return items(searchTerm=query, includeItemTypes="Playlist,MusicArtist,MusicAlbum,Audio", limit=20)


def songs_in(item: dict) -> list[dict]:
    order = "ParentIndexNumber,IndexNumber,SortName"
    match item["Type"]:
        case "Audio":
            return [item]
        case "MusicArtist":
            return items(artistIds=item["Id"], includeItemTypes="Audio", sortBy=f"Album,{order}")
        case _:
            return items(parentId=item["Id"], includeItemTypes="Audio", sortBy=order)


def best_match(what: str) -> dict | None:
    hits = find(what)
    wanted = what.strip().casefold()
    return (
        next((h for h in hits if h["Type"] != "Audio" and h["Name"].casefold() == wanted), None)
        or next((h for h in hits if h["Type"] == "Audio"), None)
        or (hits[0] if hits else None)
    )


def title(item: dict) -> str:
    artists = ", ".join(item.get("Artists") or [])
    return f"{item['Name']} - {artists}" if item.get("Type") == "Audio" and artists else item["Name"]


def clock(ticks) -> str:
    seconds = int((ticks or 0) / 10_000_000)
    return f"{seconds // 60}:{seconds % 60:02d}"


def send(session_id: str, command: str, ids: list[str]) -> None:
    batches = [ids[i : i + BATCH] for i in range(0, len(ids), BATCH)]
    if command == "PlayNext":
        batches.reverse()
    for i, batch in enumerate(batches):
        first = command if command != "PlayNow" or i == 0 else "PlayLast"
        call("POST", f"/Sessions/{session_id}/Playing", params={"playCommand": first, "itemIds": ",".join(batch)})


def play_music(what: str, ids: list[str], mode: str, shuffle: bool) -> str:
    sid = session()["Id"]
    if mode == "mix":
        seed = ids[0] if ids else (best_match(what) or {}).get("Id")
        if not seed:
            return f"Nothing in the library matches {what!r}."
        send(sid, COMMANDS[mode], [seed])
        return "Playing a mix of similar songs."
    if ids:
        songs, label = ids, None
    elif what.strip().casefold() in ("", "everything", "all", "anything"):
        songs, label = [s["Id"] for s in items(includeItemTypes="Audio", sortBy="Random", limit=200)], "the library"
    else:
        item = best_match(what)
        if not item:
            return f"Nothing in the library matches {what!r}."
        songs, label = [s["Id"] for s in songs_in(item)], title(item)
    if not songs:
        return "There are no songs in that."
    if shuffle:
        random.shuffle(songs)
    send(sid, COMMANDS[mode], songs)
    what_played = label if len(songs) == 1 and label else f"{len(songs)} songs" + (f" from {label}" if label else "")
    return {"now": "Playing", "next": "Up next:", "last": "Queued"}[mode] + f" {what_played}."


def set_volume(session_id: str, level: float) -> None:
    call(
        "POST",
        f"/Sessions/{session_id}/Command",
        json={"Name": "SetVolume", "Arguments": {"Volume": str(round(max(0, min(100, level))))}},
    )


def say_text(text: str) -> None:
    global _voice
    with _speech:
        if _voice is None:
            _voice = PiperVoice.load(VOICE)
        speech = io.BytesIO()
        with wave.open(speech, "wb") as out:
            _voice.synthesize_wav(text, out)
        speech.seek(0)
        with wave.open(speech, "rb") as src, tempfile.NamedTemporaryFile(suffix=".wav", dir="/tmp") as f:
            with wave.open(f.name, "wb") as out:
                out.setparams(src.getparams())
                # The sink sleeps when idle; leading silence keeps the first word from being clipped.
                out.writeframes(b"\0" * int(src.getframerate() * 0.4) * src.getsampwidth() * src.getnchannels())
                out.writeframes(src.readframes(src.getnframes()))
            try:
                current = session()
            except RuntimeError:
                current = {}
            state = current.get("PlayState") or {}
            duck = bool(current.get("NowPlayingItem")) and not state.get("IsPaused")
            volume = state.get("VolumeLevel") or 100
            if duck:
                set_volume(current["Id"], volume * DUCK)
            try:
                subprocess.run(["paplay", "--client-name=Hermes voice", f.name], timeout=600, check=True)
            finally:
                if duck:
                    set_volume(current["Id"], volume)


@mcp.tool()
async def search(query: str) -> list[dict]:
    """Search Felix's library by name for artists, albums, playlists and songs. Artists, albums
    and playlists come with their songs, so you can pick some and pass their ids to play()."""

    def run():
        results = []
        for hit in find(query):
            entry = {"type": hit["Type"], "name": title(hit)}
            if hit["Type"] == "Audio":
                entry["id"] = hit["Id"]
            else:
                entry["songs"] = [{"id": s["Id"], "name": title(s)} for s in songs_in(hit)[:100]]
            results.append(entry)
        return results

    return await asyncio.to_thread(run)


@mcp.tool()
async def play(what: str = "everything", ids: list[str] | None = None, mode: str = "now", shuffle: bool = False) -> str:
    """Play music on the speaker.

    what: an artist, album, song or playlist name, or "everything" for the whole library.
    ids: song ids from search(), played in this order, instead of what.
    mode: "now" replaces the queue, "next" plays after the current song, "last" adds to the
      end of the queue, "mix" plays a mix of songs similar to what (or the first id).
    shuffle: shuffle the songs first.
    """
    if mode not in COMMANDS:
        return f"mode must be one of {', '.join(COMMANDS)}."
    return await asyncio.to_thread(play_music, what, ids or [], mode, shuffle)


@mcp.tool()
async def control(action: str) -> str:
    """Control playback: "pause", "resume", "next", "previous" or "stop"."""
    commands = {"pause": "Pause", "resume": "Unpause", "next": "NextTrack", "previous": "PreviousTrack", "stop": "Stop"}
    if action not in commands:
        return f"action must be one of {', '.join(commands)}."
    await asyncio.to_thread(lambda: call("POST", f"/Sessions/{session()['Id']}/Playing/{commands[action]}"))
    return f"Done: {action}."


@mcp.tool()
async def volume(level: int) -> str:
    """Set the music volume, 0-100. It can only be changed while something is playing."""

    def run():
        current = session()
        if not current.get("NowPlayingItem"):
            return "Nothing is playing, so the volume can't be changed yet."
        set_volume(current["Id"], level)
        return f"Volume {max(0, min(100, level))}."

    return await asyncio.to_thread(run)


@mcp.tool()
async def status() -> dict:
    """What's playing on the speaker: the song, its position, whether it's paused, and the volume."""

    def run():
        current = session()
        item, state = current.get("NowPlayingItem"), current.get("PlayState") or {}
        if not item:
            return {"now_playing": None}
        return {
            "now_playing": title(item),
            "album": item.get("Album"),
            "position": f"{clock(state.get('PositionTicks'))} / {clock(item.get('RunTimeTicks'))}",
            "paused": bool(state.get("IsPaused")),
            "volume": state.get("VolumeLevel"),
        }

    return await asyncio.to_thread(run)


@mcp.tool()
async def say(text: str) -> str:
    """Speak text out loud in English. Music keeps playing, quieter, underneath.
    Keep it short and written for the ear: no markdown, links or long lists."""
    await asyncio.to_thread(say_text, text)
    return "Spoken."


if __name__ == "__main__":
    mcp.run(transport="streamable-http", host="0.0.0.0", port=8000, stateless_http=True)
