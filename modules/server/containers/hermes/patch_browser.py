from pathlib import Path


def replace(path, before, after):
    source = path.read_text()
    if before not in source and after in source:
        return
    if source.count(before) != 1:
        raise RuntimeError(f"Browser integration no longer matches {path.name}")
    path.write_text(source.replace(before, after))


root = Path("/opt/hermes/tools")
cli = root / "browser_use_cli.py"
replace(
    root / "browser_session_cdp.py",
    '    return resolve_cdp_override(raw) if raw else ""',
    '    from tools.browser_cdp_bridge import resolve_endpoint\n'
    '    return resolve_endpoint(raw) if raw else ""',
)

replace(
    cli,
    '    override = _quiet(get_cdp_override, "")',
    '    try:\n'
    '        override = get_cdp_override()\n'
    '    except Exception as exc:\n'
    '        return f"Configured desktop browser is unavailable: {exc}"',
)
