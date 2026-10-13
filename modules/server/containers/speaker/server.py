"""Hermes' speaker tools: music picked by AudioMuse-AI, played through Jellyfin, speech through Piper.

AudioMuse chooses every song: by name, by how a description sounds (CLAP), by what the lyrics are
about, and by sonic similarity to an artist or song. Its item ids are Jellyfin's, so they go
straight to the "Speaker" device in Jellyfin (the speaker-player container, Jellyfin MPV Shim),
which these tools drive through Jellyfin's remote-control API; Jellyfin shows what's playing and
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
from mcp.server.mcpserver.exceptions import ToolError
from piper import PiperVoice

PLAYER = os.environ.get("SPEAKER_PLAYER", "Speaker")
VOICE = os.environ["PIPER_VOICE"]
DUCK = 0.3
# Item ids go in the query string; batches keep it under the server's request-line limit.
BATCH = 100
COMMANDS = {"now": "PlayNow", "next": "PlayNext", "last": "PlayLast"}
# Candidates each AudioMuse search contributes before they are blended.
POOL = 300
# Reciprocal-rank fusion constant: higher flattens the gap between first and tenth place.
RRF_K = 20

mcp = MCPServer(
    "speaker",
    instructions=(
        "Felix's speaker at home: play music from his library, chosen by AudioMuse-AI, and speak "
        "text out loud."
    ),
)
audiomuse = httpx.Client(base_url=os.environ["AUDIOMUSE_URL"], timeout=60)
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
        raise ToolError(f"Jellyfin is unreachable ({type(e).__name__})") from None
    if r.status_code == 401:
        raise ToolError("Jellyfin rejected the speaker's API key")
    r.raise_for_status()
    return r.json() if r.content else None


def session() -> dict:
    found = [s for s in call("GET", "/Sessions") if s.get("DeviceName") == PLAYER and s.get("SupportsRemoteControl")]
    if not found:
        raise ToolError(f'The "{PLAYER}" player isn\'t connected to Jellyfin')
    return max(found, key=lambda s: s.get("LastActivityDate") or "")


def muse(method: str, path: str, **kwargs):
    try:
        r = audiomuse.request(method, path, **kwargs)
    except httpx.TransportError as e:
        raise ToolError(f"AudioMuse is unreachable ({type(e).__name__})") from None
    if r.status_code == 404:
        return []
    r.raise_for_status()
    return r.json()


def song(track: dict) -> dict:
    return {"id": track["item_id"], "name": f"{track['title']} - {track['author']}"}


def by_name(name: str, loose: bool = False) -> list[dict]:
    """Songs by an artist, on an album or in a playlist, or titled name; the closest kind wins.
    Only loose takes songs whose names merely contain name."""
    wanted = name.strip().casefold()
    playlists = muse("GET", "/api/search_playlists", params={"query": name})
    playlist = next((p for p in playlists if p["name"].removesuffix("_automatic").casefold() == wanted), None)
    if playlist:
        servers = muse("GET", "/api/playlists")["servers"]
        return next(s["playlists"][playlist["name"]] for s in servers if playlist["name"] in s["playlists"])
    tracks = muse("GET", "/api/search_tracks", params={"search_query": name, "end": 500})
    for field in ("author", "album", "title"):
        exact = [t for t in tracks if wanted in [part.strip().casefold() for part in t[field].split(",")]]
        if exact:
            return exact
    return tracks if loose else []


def text_match(description: str) -> list[dict]:
    return muse("POST", "/api/clap/search", json={"query": description, "limit": POOL})["results"]


def lyrics_match(theme: str) -> list[dict]:
    return muse("POST", "/api/lyrics/search/text", json={"query": theme, "limit": POOL})["results"]


def seeds_and_similar(seeds: list[dict], limit: int) -> list[dict]:
    """The seed songs, then the songs that sound most like any of them."""
    closest = {t["item_id"]: (0.0, t) for t in seeds}
    for seed in seeds[:20]:
        for t in muse("GET", "/api/similar_tracks", params={"item_id": seed["item_id"], "n": 30}):
            if t["item_id"] not in closest or t["distance"] < closest[t["item_id"]][0]:
                closest[t["item_id"]] = (t["distance"], t)
    return [t for _, t in sorted(closest.values(), key=lambda pair: pair[0])][:limit]


def fingerprint(limit: int) -> list[dict]:
    """Songs like the ones Felix plays most."""
    return muse(
        "POST",
        "/api/sonic_fingerprint/generate",
        json={"n": limit, "jellyfin_user_identifier": user_id(), "jellyfin_token": os.environ["JELLYFIN_API_KEY"]},
    )


def fuse(ranks: list[list[dict]], limit: int) -> list[dict]:
    """Blend several ranked lists: a song high in all of them beats one at the top of one."""
    score, tracks = {}, {}
    for ranked in ranks:
        for place, t in enumerate(ranked):
            score[t["item_id"]] = score.get(t["item_id"], 0) + 1 / (RRF_K + place)
            tracks[t["item_id"]] = t
    if len(ranks) > 1:
        # A song only one search found is no match for "this and that".
        found = {i for i in score if sum(i in {t["item_id"] for t in r} for r in ranks) > 1}
        score = {i: v for i, v in score.items() if i in found} or score
    return [tracks[i] for i in sorted(score, key=score.get, reverse=True)][:limit]


def user_id() -> str:
    global _user_id
    if not _user_id:
        admins = [u for u in call("GET", "/Users") if u.get("Policy", {}).get("IsAdministrator")]
        _user_id = admins[0]["Id"]
    return _user_id


def title(item: dict) -> str:
    return f"{item['Name']} - {', '.join(item['Artists'])}" if item.get("Artists") else item["Name"]


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


def pick(query: str, like: str | None, lyrics: str | None, limit: int) -> list[dict]:
    """AudioMuse's songs for the request, best first."""
    seeds = by_name(like, loose=True) if like else []
    if like and not seeds:
        raise ToolError(f"Nothing in the library matches {like!r}.")
    if not query and not lyrics:
        if not like:
            return fingerprint(limit)
        return seeds_and_similar(seeds, limit)
    if not like and not lyrics:
        named = by_name(query)
        if named:
            return named[:limit]
    ranks = []
    if query:
        ranks.append(text_match(query))
    if lyrics:
        ranks.append(lyrics_match(lyrics))
    if like:
        ranks.append(seeds_and_similar(seeds, POOL))
    return fuse(ranks, limit)


def play_music(ids: list[str], mode: str, shuffle: bool, label: str) -> str:
    if not ids:
        return "There are no songs in that."
    sid = session()["Id"]
    if shuffle:
        random.shuffle(ids)
    send(sid, COMMANDS[mode], ids)
    return {"now": "Playing", "next": "Up next:", "last": "Queued"}[mode] + f" {label}."


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
            except ToolError:
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


DISCOVER = """
    query: a name (artist, album, song or one of the AudioMuse playlists) or a description of
      the sound, e.g. "moody, melancholic, dreamy female vocals". A name returns its songs; a
      description finds songs that sound like it. Spell short moods out: "moody, melancholic,
      slow, dreamy" works better than "moody".
    like: an artist or song name: songs that sound like it (its own songs included). With query,
      songs that sound like it and fit the description.
    lyrics: what the lyrics are about, e.g. "missing someone late at night".
    Leave all three empty for songs like the ones Felix plays most.
    limit: how many songs.
"""


@mcp.tool(
    description="Find songs in Felix's library with AudioMuse, best first, to look through or to pass "
    "some of their ids to play().\n" + DISCOVER
)
async def search(query: str = "", like: str | None = None, lyrics: str | None = None, limit: int = 30) -> list[dict]:
    def run():
        return [song(t) for t in pick(query, like, lyrics, limit)]

    return await asyncio.to_thread(run)


@mcp.tool(
    description="""Play music on the speaker, chosen the same way as search().

    ids: song ids from search(), played in this order, instead of query, like and lyrics.
    mode: "now" replaces the queue, "next" plays after the current song, "last" adds to the end.
    shuffle: shuffle the songs first.
"""
    + DISCOVER
)
async def play(
    query: str = "",
    like: str | None = None,
    lyrics: str | None = None,
    ids: list[str] | None = None,
    mode: str = "now",
    shuffle: bool = False,
    limit: int = 50,
) -> str:
    if mode not in COMMANDS:
        return f"mode must be one of {', '.join(COMMANDS)}."

    def run():
        if ids:
            return play_music(list(ids), mode, shuffle, f"{len(ids)} songs")
        tracks = pick(query, like, lyrics, limit)
        if not tracks:
            return "AudioMuse found nothing for that."
        first = song(tracks[0])["name"]
        label = first if len(tracks) == 1 else f"{len(tracks)} songs, starting with {first}"
        return play_music([t["item_id"] for t in tracks], mode, shuffle, label)

    return await asyncio.to_thread(run)


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
