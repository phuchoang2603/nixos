"""Answer Hermes' Bitwarden unlock prompt from a stored master password.

Only the CLI, TUI and Desktop app register a master-password prompt, so Discord sessions can never
unlock the vault. This installs a process-wide fallback prompt that answers for the ``bitwarden``
backend; a surface's own prompt still wins. Unattended contexts (cron, API server) stay locked
because ``can_prompt_here`` refuses them before any prompt is consulted.
"""

from __future__ import annotations

import logging
import os

logger = logging.getLogger(__name__)

ENV = "BW_MASTER_PASSWORD"


def register(ctx) -> None:
    # Taken out of the environment so subprocesses (execute_code, MCP servers) never inherit it.
    password = os.environ.pop(ENV, "")
    if not password:
        return
    from agent.vault_backends import unlock

    surface_prompt = unlock.get_unlock_prompt_callback

    def stored(backend: str, _display_name: str) -> str:
        return password if backend == "bitwarden" else ""

    def get_unlock_prompt_callback():
        return surface_prompt() or stored

    unlock.get_unlock_prompt_callback = get_unlock_prompt_callback
    logger.info("Bitwarden vault unlocks from the stored master password")
