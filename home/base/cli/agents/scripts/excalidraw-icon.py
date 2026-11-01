"""Search svgl/Iconify icons and place them on the Excalidraw canvas."""

import argparse
import base64
import hashlib
import json
import os
import re
import secrets
import sys
import urllib.error
import urllib.parse
import urllib.request

SVGL_API = "https://api.svgl.app"
SVGL_LIBRARY = "https://svgl.app/library"
ICONIFY_API = os.environ.get("ICONIFY_API_URL", "https://api.iconify.design")
USER_AGENT = "excalidraw-icon/1.0"
DEFAULT_SIZE = 96


def fail(msg, code=1):
    print(json.dumps({"success": False, "error": msg}), file=sys.stderr)
    sys.exit(code)


def http(url, data=None, method=None):
    headers = {"User-Agent": USER_AGENT}
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.read().decode()
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"{e.code} {e.reason} for {url}") from e
    except urllib.error.URLError as e:
        raise RuntimeError(f"cannot reach {url}: {e.reason}") from e


def svgl_slug(route_url):
    return os.path.basename(route_url).removesuffix(".svg")


def svgl_refs(route):
    if isinstance(route, str):
        return f"svgl:{svgl_slug(route)}"
    return {k: f"svgl:{svgl_slug(v)}" for k, v in route.items()}


def search_svgl(query, limit):
    q = urllib.parse.quote(query)
    raw = json.loads(http(f"{SVGL_API}?search={q}"))
    if not isinstance(raw, list):
        return []
    out = []
    for item in raw[:limit]:
        entry = {
            "source": "svgl",
            "title": item.get("title"),
            "category": item.get("category"),
            "ref": svgl_refs(item["route"]),
        }
        if item.get("wordmark"):
            entry["wordmark"] = svgl_refs(item["wordmark"])
        out.append(entry)
    return out


def search_iconify(query, limit, prefix):
    params = {"query": query, "limit": max(limit, 32)}
    if prefix:
        params["prefixes"] = prefix
    url = f"{ICONIFY_API}/search?{urllib.parse.urlencode(params)}"
    raw = json.loads(http(url))
    icons = raw.get("icons", [])[:limit]
    return [{"source": "iconify", "ref": name} for name in icons]


def parse_ref(ref):
    if ref.startswith("svgl:"):
        return "svgl", ref[5:]
    if ref.startswith("iconify:"):
        ref = ref[8:]
    if ref.count(":") != 1:
        fail(f"bad icon ref '{ref}': use svgl:<slug> or <prefix>:<name>", 2)
    return "iconify", ref


def fetch_svg(ref, color=None):
    source, name = parse_ref(ref)
    if source == "svgl":
        url = f"{SVGL_LIBRARY}/{urllib.parse.quote(name)}.svg"
    else:
        prefix, icon = name.split(":")
        params = {"height": "256"}
        if color:
            params["color"] = color
        url = f"{ICONIFY_API}/{prefix}/{icon}.svg?{urllib.parse.urlencode(params)}"
    svg = http(url).strip()
    if "<svg" not in svg:
        fail(f"'{ref}' did not return an SVG ({url})")
    return svg


def normalize_svg(svg):
    """Give the root <svg> explicit px width/height so browsers render it at
    the right aspect ratio instead of the 300x150 default."""
    m = re.search(r"<svg\b[^>]*>", svg, re.S)
    if not m:
        fail("no <svg> root element found")
    root = m.group(0)
    vb = re.search(r'viewBox\s*=\s*["\']([^"\']+)["\']', root)
    if vb:
        parts = [float(p) for p in re.split(r"[\s,]+", vb.group(1).strip())]
        vw, vh = parts[2], parts[3]
    else:
        def dim(attr):
            d = re.search(rf'\b{attr}\s*=\s*["\']([\d.]+)', root)
            return float(d.group(1)) if d else 256.0
        vw, vh = dim("width"), dim("height")
    scale = 256.0 / max(vw, vh)
    w, h = round(vw * scale, 2), round(vh * scale, 2)
    new_root = re.sub(r'\s(width|height)\s*=\s*["\'][^"\']*["\']', "", root)
    if "xmlns=" not in new_root:
        new_root = new_root.replace("<svg", '<svg xmlns="http://www.w3.org/2000/svg"', 1)
    new_root = new_root.replace("<svg", f'<svg width="{w}" height="{h}"', 1)
    return svg.replace(root, new_root, 1), vw / vh


def build_icon(spec, index):
    ref = spec["ref"]
    size = float(spec.get("size", DEFAULT_SIZE))
    x, y = float(spec.get("x", 0)), float(spec.get("y", 0))
    svg, aspect = normalize_svg(fetch_svg(ref, spec.get("color")))

    if aspect >= 1:
        width, height = size, round(size / aspect, 2)
    else:
        width, height = round(size * aspect, 2), size

    digest = hashlib.sha1(svg.encode()).hexdigest()[:20]
    file_id = f"icon-{digest}"
    data_url = "data:image/svg+xml;base64," + base64.b64encode(svg.encode()).decode()
    slug = re.sub(r"[^a-z0-9]+", "-", ref.split(":")[-1].lower()).strip("-")
    elem_id = spec.get("id") or f"icon-{slug}-{secrets.token_hex(2)}"

    elements = [{
        "id": elem_id,
        "type": "image",
        "x": x,
        "y": y,
        "width": width,
        "height": height,
        "fileId": file_id,
        "status": "saved",
        "scale": [1, 1],
        "strokeColor": "transparent",
        "backgroundColor": "transparent",
    }]
    result = {"ref": ref, "id": elem_id, "fileId": file_id,
              "x": x, "y": y, "width": width, "height": height}

    label = spec.get("label")
    if label:
        font_size = float(spec.get("fontSize", 18))
        label_id = f"{elem_id}-label"
        # With textAlign=center the frontend treats x as the text's center
        # and measures the real width itself.
        elements.append({
            "id": label_id,
            "type": "text",
            "x": round(x + width / 2, 2),
            "y": round(y + height + 8, 2),
            "height": round(font_size * 1.25, 2),
            "text": label,
            "fontSize": font_size,
            "fontFamily": spec.get("fontFamily", "cascadia"),
            "textAlign": "center",
            "strokeColor": spec.get("labelColor", "#1e1e1e"),
        })
        result["labelId"] = label_id

    file_entry = {"id": file_id, "dataURL": data_url,
                  "mimeType": "image/svg+xml", "created": index}
    return elements, file_entry, result


def cmd_search(args):
    results = []
    if args.source in ("all", "svgl") and not args.prefix:
        results += search_svgl(args.query, args.limit)
    if args.source in ("all", "iconify"):
        results += search_iconify(args.query, args.limit, args.prefix)
    print(json.dumps(results, indent=2))


def cmd_svg(args):
    svg, _ = normalize_svg(fetch_svg(args.ref, args.color))
    if args.out:
        with open(args.out, "w") as f:
            f.write(svg + "\n")
        print(json.dumps({"success": True, "ref": args.ref, "out": args.out}))
    else:
        print(svg)


def cmd_add(args):
    if args.ref == "-":
        specs = json.load(sys.stdin)
        if not isinstance(specs, list):
            fail("stdin must be a JSON array of icon specs", 2)
    else:
        spec = {"ref": args.ref, "x": args.x, "y": args.y, "size": args.size}
        for key in ("label", "id", "color"):
            if getattr(args, key):
                spec[key] = getattr(args, key)
        specs = [spec]

    all_elements, files, results = [], {}, []
    for i, spec in enumerate(specs):
        if "ref" not in spec:
            fail(f"spec #{i} is missing 'ref'", 2)
        elements, file_entry, result = build_icon(spec, i)
        all_elements += elements
        files[file_entry["id"]] = file_entry
        results.append(result)

    base = args.url.rstrip("/")
    # Files first, so the frontend already has the image when elements arrive.
    http(f"{base}/api/files", {"files": list(files.values())}, "POST")
    resp = json.loads(http(f"{base}/api/elements/batch", {"elements": all_elements}, "POST"))
    if not resp.get("success"):
        fail(f"canvas rejected elements: {resp.get('error')}")
    print(json.dumps({"success": True, "icons": results}, indent=2))


def main():
    p = argparse.ArgumentParser(
        prog="excalidraw-icon",
        description="Search svgl/Iconify icons and place them on the Excalidraw canvas.",
        epilog="Refs: svgl:<slug> (e.g. svgl:docker, svgl:github_light) or "
               "Iconify <prefix>:<name> (e.g. logos:kubernetes, selfhst:proxmox, mdi:server).",
    )
    p.add_argument("--url", default=os.environ.get("EXPRESS_SERVER_URL", "http://127.0.0.1:3000"),
                   help="canvas URL (default: $EXPRESS_SERVER_URL)")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("search", help="search icons (JSON output)")
    s.add_argument("query")
    s.add_argument("--source", choices=["all", "svgl", "iconify"], default="all")
    s.add_argument("--prefix", help="Iconify set(s), comma-separated (e.g. logos,selfhst)")
    s.add_argument("--limit", type=int, default=10)
    s.set_defaults(func=cmd_search)

    a = sub.add_parser("add", help="place icon(s) on the canvas; ref '-' reads a JSON array of specs from stdin")
    a.add_argument("ref")
    a.add_argument("--x", type=float, default=0)
    a.add_argument("--y", type=float, default=0)
    a.add_argument("--size", type=float, default=DEFAULT_SIZE, help=f"longest side in px (default {DEFAULT_SIZE})")
    a.add_argument("--label", help="text label centered below the icon")
    a.add_argument("--id", help="element id (default: icon-<name>-<rand>)")
    a.add_argument("--color", help="Iconify only: color for monochrome icons, e.g. '#326ce5'")
    a.set_defaults(func=cmd_add)

    v = sub.add_parser("svg", help="print or save the normalized SVG")
    v.add_argument("ref")
    v.add_argument("--color")
    v.add_argument("--out")
    v.set_defaults(func=cmd_svg)

    args = p.parse_args()
    try:
        args.func(args)
    except RuntimeError as e:
        fail(str(e), 3)


if __name__ == "__main__":
    main()
