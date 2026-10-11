"""Autocomplete for the ``name`` option of Discord's ``/model``.

Hermes declares the option as free text, so models can only be browsed through the bare ``/model``
picker. This attaches an autocomplete callback fed by the same catalog as that picker. The hook sits
on discord.py's ``CommandTree.add_command`` because the Discord adapter may load after this plugin.
Suggestions carry ``--provider`` so a model id that also exists on a native provider stays on the
route it was listed under.
"""

from __future__ import annotations

import asyncio
import logging
import sys
import time

import discord

logger = logging.getLogger(__name__)

# Seconds a fetched catalog is served before the next keystroke refreshes it in the background.
TTL = 300
# Discord drops autocomplete responses after 3 s, so a cold fetch is waited on for less.
COLD_WAIT = 2.0
# Discord caps autocomplete at 25 choices of at most 100 characters each.
MAX_CHOICES = 25
MAX_CHOICE_LEN = 100

_entries: list[tuple[str, str, str]] = []
_fetched = 0.0
_pending: asyncio.Future | None = None


def _adapter():
    """The live Discord adapter of the running gateway, or None outside the gateway."""
    run = sys.modules.get("gateway.run")
    runner = run._gateway_runner_ref() if run else None
    if runner is None:
        return None
    return next((a for p, a in runner.adapters.items() if getattr(p, "value", p) == "discord"), None)


def _load() -> list[tuple[str, str, str]]:
    """``(model, provider slug, provider name)`` for every model the /model picker would offer."""
    from gateway.run import _load_gateway_config
    from hermes_cli.config import get_compatible_custom_providers
    from hermes_cli.model_switch_providers import list_picker_providers

    cfg = _load_gateway_config() or {}
    model = cfg.get("model") or {}
    providers = list_picker_providers(
        current_provider=model.get("provider", ""),
        current_base_url=model.get("base_url", ""),
        current_model=model.get("default", ""),
        user_providers=cfg.get("providers"),
        custom_providers=get_compatible_custom_providers(cfg),
        excluded_providers=(cfg.get("model_catalog") or {}).get("excluded_providers"),
        non_blocking_catalogs=True,
        probe_custom_providers=False,
        probe_current_custom_provider=True,
    )
    return [(m, p["slug"], p.get("name") or p["slug"]) for p in providers for m in p.get("models", [])]


async def _catalog() -> list[tuple[str, str, str]]:
    global _entries, _fetched, _pending
    if _pending is None and time.monotonic() - _fetched > TTL:
        _pending = asyncio.ensure_future(asyncio.to_thread(_load))
    if _pending is not None and (_pending.done() or not _entries):
        try:
            _entries = await asyncio.wait_for(asyncio.shield(_pending), COLD_WAIT)
        except asyncio.TimeoutError:
            return _entries
        except Exception:
            logger.warning("Model catalog for /model autocomplete failed", exc_info=True)
        _fetched = time.monotonic()
        _pending = None
    return _entries


async def _autocomplete(interaction: discord.Interaction, current: str) -> list:
    adapter = _adapter()
    try:
        allowed, _reason = adapter._evaluate_slash_authorization(interaction)
    except Exception:
        return []
    if not allowed:
        return []
    query = (current or "").strip().lower()
    entries = await _catalog()
    multiple = len({slug for _m, slug, _n in entries}) > 1
    choices = []
    for model, slug, name in entries:
        if query and query not in model.lower():
            continue
        value = f"{model} --provider {slug}"
        if len(value) > MAX_CHOICE_LEN:
            continue
        label = f"{model} ({name})" if multiple else model
        choices.append(discord.app_commands.Choice(name=label[:MAX_CHOICE_LEN], value=value))
        if len(choices) >= MAX_CHOICES:
            break
    return choices


def _install() -> None:
    tree_cls = discord.app_commands.CommandTree
    if getattr(tree_cls.add_command, "_model_autocomplete", False):
        return
    add_command = tree_cls.add_command

    def patched(self, command, /, *args, **kwargs):
        if isinstance(command, discord.app_commands.Command) and command.name == "model":
            param = command._params.get("name")
            if param is not None and param.autocomplete is None and not param.choices:
                command.autocomplete("name")(_autocomplete)
        return add_command(self, command, *args, **kwargs)

    patched._model_autocomplete = True
    tree_cls.add_command = patched


def register(ctx) -> None:
    _install()
