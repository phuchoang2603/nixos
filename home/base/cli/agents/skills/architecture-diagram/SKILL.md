---
name: architecture-diagram
description: Create or revise repository architecture diagrams as editable SVG files, with deployment boundaries, HTML service boxes, and labeled orthogonal data flows. Use for system topology and infrastructure maps intended for READMEs or documentation.
---

# Architecture diagrams

Read the implementation, deployment manifests, and existing architecture notes before drawing. Distinguish current behavior from proposals and verify ownership, ingress, synchronous calls, asynchronous delivery, and external systems. Preserve the user's reference style when provided.

For a large topology map, view [assets/reference-topology.png](assets/reference-topology.png) as a visual reference; its components are illustrative, not architecture facts for the current project.

Use a technical topology map: a light canvas, subtle deployment or namespace boundaries, compact white component boxes, small technology tags, restrained colors, and a flow legend. Main boxes represent deployable units or explicitly labeled external systems; libraries and topics belong inside their host. Keep components aligned and leave gutters for connectors. Group shared support services in dashed boxes and explain omitted connections.

Use native SVG paths, markers, labels, and numbered flow badges around XHTML boxes inside `foreignObject`. Keep the SVG self-contained: inline CSS, no scripts, external fonts, remote images, or network dependencies. Include a `viewBox`, accessible title and description, and stable component IDs. Scope CSS to component classes. Optional icons should be embedded vectors; avoid making logos necessary to understand a component.

Route connectors horizontally and vertically through gutters, never through unrelated components. Use one color and an independent numbering sequence per flow, such as H for HTTP/gRPC, C for catalog events, S for saga messages, and P for payments. Label the exchanged data or action. State whether a diagram shows calls or payload direction; distinguish requests from outcomes when their return path matters. Do not imply a direct broker publish when a system actually uses an outbox and CDC. Use solid lines for primary flows and dashed lines for secondary relationships.

## Rendering

The standard-library renderer at [scripts/render.py](scripts/render.py) accepts an explicit JSON layout and emits standalone SVG:

```sh
python3 /path/to/architecture-diagram/scripts/render.py architecture.json architecture.svg
```

Keep the layout JSON adjacent to the generated SVG when the repository benefits from repeatable edits. Inspect [assets/example.json](assets/example.json) for the input shape. Coordinates use pixels with the origin at the top left. `box` means `[x, y, width, height]`; edge `points` are orthogonal waypoints. Optional `badge` is `[x, y]`; `label` is `[x, y, text]`, with `anchor` selecting `start`, `middle`, or `end`. `bus: true` omits the arrowhead. Flow colors are `web`, `catalog`, `saga`, `payment`, and `state`. Node `support: true` gives a dashed border. Notes provide explanatory text and a legend. The renderer validates XML, unique node IDs, node/connector bounds, and orthogonal routing; it does not automatically route edges or detect all label collisions.

The renderer is a starting point, not a requirement to force every diagram into the same layout. Adjust its output or build a custom SVG if the task needs a different visual vocabulary.

## Review and delivery

Preview the actual SVG as an HTML `img`, not only as a directly opened SVG. Check the full-resolution image and the intended README width. Look for clipping, overflowing HTML boxes, labels touching badges or other labels, connectors crossing boxes, and ambiguous arrowheads. Iterate until the topology is readable. An XML parser alone cannot validate browser layout.

Use the host's browser or HTML preview tools when available. In T3, preview with `html_preview` and publish the finished image in a self-contained HTML page through `html_render`. Else use the environment's available image/browser preview. Do not require a shared canvas server.

Embed the file with a relative Markdown image reference and change only the affected documentation. Browser support for `foreignObject` does not establish GitHub or other renderer support. Report what was actually verified; if the destination strips the HTML, offer native SVG text/rectangles or a raster export, and verify the chosen fallback rather than promising compatibility.
