"""Unattended applicant account credentials using Hermes' encrypted local store.

The agent supplies public metadata, never a password. Creation persists a fresh
credential before filling both registration fields; retries reuse the same item.
The agent still inspects the site response before declaring an account created.
"""

from __future__ import annotations

import fcntl
import json
import secrets
import string
import threading
from contextlib import contextmanager

_lock = threading.Lock()


@contextmanager
def _account_lock():
    from hermes_constants import get_hermes_home

    path = get_hermes_home() / "state" / "application-accounts.lock"
    path.parent.mkdir(parents=True, exist_ok=True)
    with _lock, path.open("a") as stream:
        fcntl.flock(stream, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(stream, fcntl.LOCK_UN)


def _password(length: int) -> str:
    groups = (string.ascii_uppercase, string.ascii_lowercase, string.digits, "!@#$%*-_")
    chars = [secrets.choice(group) for group in groups]
    chars.extend(secrets.choice("".join(groups)) for _ in range(length - len(chars)))
    secrets.SystemRandom().shuffle(chars)
    return "".join(chars)


def _account(args: dict, task_id: str) -> str:
    from agent.redact import register_vault_redaction_value
    from agent.vault_login_classifier import build_fill_js, build_inspection_js
    from agent.vault_store import get_vault_store, normalize_origin
    from tools import browser_vault_tool as vault

    def error(message, **extra):
        return json.dumps({"success": False, "error": message, **extra})

    origin = normalize_origin(str(args.get("origin") or ""))
    if not origin.startswith("https://"):
        return error("Applicant credentials require an HTTPS origin.")
    identifier = str(args.get("identifier") or "").strip()
    mode = args.get("mode", "login")
    length = args.get("password_length", 24)
    if not identifier or mode not in {"create", "login"}:
        return error("Supply the applicant identifier and mode=create or login.")
    if isinstance(length, bool) or not isinstance(length, int) or not 12 <= length <= 128:
        return error("password_length must be an integer between 12 and 128.")
    vault._focus_bound_origin(task_id, origin, "login")
    if vault._current_page_origin(task_id) != origin:
        return error("Open the applicant password form on the requested origin first.")
    nonce = secrets.token_hex(8)
    inspection = vault._eval_js(task_id, build_inspection_js(nonce))
    controls = vault._parse_json_result(inspection.get("result")) if inspection.get("success") else None
    if isinstance(controls, str):
        controls = vault._parse_json_result(controls)
    if not isinstance(controls, list):
        return error("Could not inspect the applicant form.")
    fields = [c for c in controls if c.get("type") == "password"]
    # Do not spray a credential across unrelated sign-in / password-change forms.
    if not fields or len(fields) > (2 if mode == "create" else 1) or len({c.get("formIndex") for c in fields}) != 1:
        return error("Expose only the intended sign-in or registration form, then retry.")
    if mode == "login" and any("new-password" in c.get("autocomplete", "") for c in fields):
        return error("This is a registration form; use mode=create to fill a new account.")

    store = get_vault_store()
    with _account_lock():
        matches = [m for m in store.list_items() if m.kind == "login" and m.origin == origin
                   and (m.identifier or "").casefold() == identifier.casefold()]
        if len(matches) > 1:
            return error("Multiple saved logins match; resolve the duplicate account entries before retrying.")
        created = False
        if matches:
            meta = matches[0]
            password = store.resolve_secret(meta.id)["password"]
        elif mode == "login":
            return error("No local login exists. Use existing SSO or email-based recovery; "
                         "use mode=create only if the site asks to register a new applicant.")
        else:
            limits = [c["maxLength"] for c in fields if c.get("maxLength", 0) and c["maxLength"] > 0]
            length = min([length, *limits])
            if length < 12:
                return error("The site's password maximum is below 12 characters.")
            password = _password(length)
            meta = store.add_item("login", str(args.get("label") or origin),
                                  {"identifier_type": "email" if "@" in identifier else "username",
                                   "identifier": identifier, "password": password}, origin=origin)
            created = True

    # Register before injection; later browser results cannot echo the secret.
    register_vault_redaction_value(password)
    fills = [{"index": c["index"], "token": "current-password", "value": password} for c in fields]
    try:
        result = vault._eval_js_secret(task_id, build_fill_js(fills, expected_origin=origin, nonce=nonce))
    except Exception:
        return error("Credential saved; browser fill failed. Retry the same account without regenerating it.",
                     handle=meta.id)
    finally:
        del password
        fills.clear()
    parsed = vault._parse_json_result(result.get("result"))
    if isinstance(parsed, str):
        parsed = vault._parse_json_result(parsed)
    filled = parsed.get("filled", 0) if isinstance(parsed, dict) else 0
    success = bool(result.get("success") and filled == len(fields))
    return json.dumps({"success": success, "handle": meta.id, "origin": origin, "identifier": identifier,
                       "credential_created": created, "filled_fields": filled,
                       "next": "Fill the identifier and required consent, submit once, and inspect the site response. "
                               "This tool fills fields; it does not establish that the account exists."
                       if success else "Credential saved. Reopen the correct form and retry; do not generate another password."})


def handle_account(args: dict, **kwargs) -> str:
    from tools.browser_vault_tool import _fenced_page_op

    task_id = kwargs.get("task_id") or "default"
    try:
        return _fenced_page_op(task_id, lambda: _account(args, task_id))
    except Exception:
        # Vault / CDP exceptions may carry secret-bearing expressions: never echo them.
        return json.dumps({"success": False, "error": "Applicant credential operation failed; no secret was returned."})


SCHEMA = {
    "name": "browser_application_account",
    "description": (
        "Fill applicant registration or sign-in without asking the user to set up a vault login. "
        "Use only for applicant accounts authorized by the user. mode=create generates a strong unique "
        "password, saves it encrypted for the exact site origin, and fills password AND confirmation. "
        "Retries reuse the saved credential. mode=login reuses it later. No password reaches the model. "
        "Open the intended form with browser_exec first. Fill email/username and consent normally, then "
        "submit and verify the site's response. Credentials remain in the encrypted local store."
    ),
    "parameters": {
        "type": "object",
        "properties": {
            "origin": {"type": "string", "description": "Exact HTTPS origin of the applicant form."},
            "identifier": {"type": "string", "description": "Applicant email or username."},
            "mode": {"type": "string", "enum": ["create", "login"]},
            "label": {"type": "string", "description": "Company or applicant portal name."},
            "password_length": {"type": "integer", "minimum": 12, "maximum": 128,
                                "description": "New credential length, default 24. Does not rotate existing passwords."},
        },
        "required": ["origin", "identifier", "mode"],
        "additionalProperties": False,
    },
}


def register(ctx) -> None:
    from toolsets import create_custom_toolset

    # A named exclusion leaves browser_exec enabled; upstream's browser group
    # includes it alongside the interactive Vault tools.
    create_custom_toolset("interactive-vault", "Interactive password-manager workflow", tools=[
        "browser_vault_list", "browser_vault_unlock", "browser_vault_fill",
        "browser_vault_save_login", "browser_vault_enter_code",
    ])
    from tools import browser_vault_tool as vault

    ctx.register_tool(name=SCHEMA["name"], toolset="application-accounts", schema=SCHEMA,
                      handler=handle_account, check_fn=vault._check_vault_available)
