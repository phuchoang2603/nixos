from urllib.parse import urlsplit, urlunsplit


def resolve_endpoint(raw):
    from tools.browser_session_cdp import resolve_cdp_override

    endpoint = urlsplit(raw)
    if endpoint.hostname not in {"localhost", "127.0.0.1", "::1"}:
        return resolve_cdp_override(raw)

    from tools.bot_desktop import runtime, sandbox_host
    from tools.environments import streams

    env = runtime._sandbox_env(create=True)
    if env is None:
        return resolve_cdp_override(raw)
    runtime.ensure_started_for_tool()
    remote_port = endpoint.port or (443 if endpoint.scheme in {"https", "wss"} else 80)
    port = streams.forward_port(env, remote_port, remote_host=endpoint.hostname,
                                user=sandbox_host._user_for(env))
    authority = f"127.0.0.1:{port}"
    reachable = urlunsplit(endpoint._replace(netloc=authority))
    resolved = urlsplit(resolve_cdp_override(reachable))
    if resolved.scheme not in {"ws", "wss"}:
        raise RuntimeError("Desktop Chrome did not return a DevTools WebSocket endpoint.")
    if resolved.hostname not in {"localhost", "127.0.0.1", "::1"}:
        raise RuntimeError("Desktop Chrome advertised a non-loopback DevTools endpoint.")
    return urlunsplit(resolved._replace(netloc=authority))
