#!/usr/bin/env python3
import argparse
import json
from html import escape
from pathlib import Path
from xml.etree import ElementTree


COLORS = {"web": "#2776c7", "catalog": "#239653", "saga": "#9560ba", "payment": "#e76c22", "state": "#8895a9"}


def esc(value):
    return escape(str(value), quote=True)


def text(x, y, value, size=15, color="#46556e", anchor="start", mono=False):
    font = "ui-monospace,Consolas,monospace" if mono else "Arial,Helvetica,sans-serif"
    return f'<text x="{x}" y="{y}" font-family="{font}" font-size="{size}" fill="{color}" text-anchor="{anchor}">{esc(value)}</text>'


def render(data):
    width, height = data["width"], data["height"]
    ids = [node["id"] for node in data["nodes"]]
    if len(ids) != len(set(ids)):
        raise ValueError("Node IDs must be unique")
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title description">', f'<title id="title">{esc(data["title"])}</title>', f'<desc id="description">{esc(data["description"])}</desc>', '<defs>']
    for name, color in COLORS.items():
        parts.append(f'<marker id="arrow-{name}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 Z" fill="{color}"/></marker>')
    parts.extend(['</defs>', f'<rect width="{width}" height="{height}" fill="#f7f8fa"/>'])
    parts.append(text(30, 35, data.get("eyebrow", "SYSTEM ARCHITECTURE"), 13, mono=True))
    parts.append(text(30, 65, data["title"], 23, "#23324b"))
    for zone in data.get("zones", []):
        x, y, w, h = zone["box"]
        dash = ' stroke-dasharray="6 5"' if zone.get("dashed") else ""
        parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{esc(zone.get("fill", "#edf0f5"))}" stroke="#ccd4e0" stroke-width="1.5"{dash}/>')
        parts.append(text(x + 18, y + 27, zone["label"], 13, mono=True))
    for edge in data["edges"]:
        points = edge["points"]
        for x, y in points:
            if not (0 <= x <= width and 0 <= y <= height):
                raise ValueError(f"Edge outside canvas: {edge}")
        if any(a[0] != b[0] and a[1] != b[1] for a, b in zip(points, points[1:])):
            raise ValueError(f"Connector must be orthogonal: {edge}")
        flow = edge["flow"]
        dash = ' stroke-dasharray="5 4"' if edge.get("dashed") else ""
        arrow = f' marker-end="url(#arrow-{flow})"' if not edge.get("bus") else ""
        parts.append(f'<polyline points="{" ".join(f"{x},{y}" for x, y in points)}" fill="none" stroke="{COLORS[flow]}" stroke-width="1.8" stroke-linejoin="round"{dash}{arrow}/>')
    parts.append('<style>.unit{box-sizing:border-box;width:100%;height:100%;padding:12px 13px;background:#fff;border:1.4px solid #aeb9cb;border-radius:9px;color:#26364f;font-family:Arial,Helvetica,sans-serif;text-align:center;position:relative;display:flex;flex-direction:column;justify-content:center}.unit .tag{position:absolute;top:7px;left:8px;border:1px solid #d1d8e3;border-radius:3px;padding:1px 4px;font:10px ui-monospace,Consolas,monospace;color:#62728c}.unit .icon{position:absolute;right:10px;top:9px;color:#65748b;font-size:16px}.unit h2{font-size:18px;font-weight:600;margin:15px 0 5px}.unit p{font:12px/1.45 ui-monospace,Consolas,monospace;margin:0;color:#52627c}.unit.support{border-style:dashed;background:#fafbfd}.unit.support h2{margin-top:8px}</style>')
    for node in data["nodes"]:
        x, y, w, h = node["box"]
        if min(x, y) < 0 or x + w > width or y + h > height:
            raise ValueError(f'Node outside canvas: {node["id"]}')
        support = " support" if node.get("support") else ""
        icon = {"database": "▱", "broker": "⋮", "service": "◇", "browser": "▣", "cloud": "☁", "gateway": "⇄"}.get(node.get("icon", "service"), "◇")
        lines = "<br />".join(esc(line) for line in node.get("lines", []))
        parts.append(f'<foreignObject id="{esc(node["id"])}" x="{x}" y="{y}" width="{w}" height="{h}"><div xmlns="http://www.w3.org/1999/xhtml" class="unit{support}"><span class="tag">{esc(node.get("tag", "service"))}</span><span class="icon">{icon}</span><h2>{esc(node["title"])}</h2><p>{lines}</p></div></foreignObject>')
    for edge in data["edges"]:
        if "badge" in edge:
            x, y = edge["badge"]
            parts.append(f'<circle cx="{x}" cy="{y}" r="13" fill="#fff" stroke="{COLORS[edge["flow"]]}" stroke-width="1.8"/>')
            parts.append(text(x, y + 4, edge["id"], 10, "#23324b", "middle", mono=True))
        if "label" in edge:
            x, y, value = edge["label"]
            parts.append(text(x, y, value, edge.get("fontSize", 13), anchor=edge.get("anchor", "middle")))
    for note in data.get("notes", []):
        parts.append(text(note["x"], note["y"], note["text"], note.get("size", 14), note.get("color", "#52627c"), note.get("anchor", "start"), note.get("mono", False)))
    result = "\n".join(parts + ['</svg>', ''])
    ElementTree.fromstring(result)
    return result


def main():
    parser = argparse.ArgumentParser(description="Render an architecture map with HTML service boxes and SVG connectors.")
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.write_text(render(json.loads(args.source.read_text())))


if __name__ == "__main__":
    main()
