---
name: excalidraw-skill
description: Excalidraw canvas toolkit for creating, editing, and refining diagrams on a live canvas, including brand logos and icons from svgl/Iconify. Use when an agent needs to (1) draw or lay out diagrams, (2) iteratively refine them by describing the scene and screenshotting its own work, (3) export/import .excalidraw files or PNG/SVG images, (4) save/restore canvas snapshots, (5) convert Mermaid to Excalidraw, or (6) perform element-level CRUD, alignment, distribution, grouping, duplication, and locking. Drives the shared canvas at $EXPRESS_SERVER_URL via the Executor MCP server's excalidraw tools or the CLI (npx -y mcp-excalidraw-server@2.1.2 <command>); the REST API is an equivalent fallback.
---

# Excalidraw Skill

## Step 0: Pick an Interface

All interfaces drive one shared canvas server running in Docker on the home server, published at `$EXPRESS_SERVER_URL` (`https://excalidraw.home.phuchoang.sbs`, LAN/VPN only). It is always running — never `start`/`stop` it, and never spawn a local canvas on `127.0.0.1:3000`. Other agents may be using the same canvas: `describe` before drawing, and only `clear --yes` when the user asks for a fresh canvas. The canvas is in-memory, so `export` anything worth keeping.

Pick the first interface that applies:

1. **MCP tools via Executor** — if the `executor` MCP server is in your tool list, find the excalidraw tools with its `search` tool (e.g. "excalidraw describe scene") and call them with `invoke`, or batch several calls in one `execute` script. Prefer them for drawing, inspecting, and screenshots: results land directly in your context. Tool names in this skill and the cheatsheet are the bare excalidraw tool names (e.g. `batch_create_elements`); use the exact IDs `search` returns. **Do not use MCP file I/O tools (`export_scene`, `import_scene`, `export_to_image`) to write or read files** — they run inside the Executor container, not on this machine. Use the CLI for anything touching local files.
2. **CLI** — for file I/O (export/import into the repo, PNG/SVG to disk), or when no MCP tools are present:
   ```bash
   npx -y mcp-excalidraw-server@2.1.2 <command>
   ```
   The CLI reads `EXPRESS_SERVER_URL` from the environment; if it's unset, pass `--url https://excalidraw.home.phuchoang.sbs`. Because the URL is non-loopback, the CLI never auto-starts a local server. MCP and CLI operate on the same canvas, so you can draw via MCP and `export` via CLI.
3. **REST API** (last resort, e.g. from application code): HTTP endpoints on `$EXPRESS_SERVER_URL` — see `references/cheatsheet.md` for payloads.

Two helper commands work alongside MCP and CLI on the same canvas — prefer them over hand-writing elements:
- `excalidraw-icon` — place logos/icons (svgl, Iconify). See **Icons & Logos**.
- `excalidraw-connect` — draw orthogonal (elbow) arrows between element ids, bound to both ends, with a numbered label. See **Arrows: Always Orthogonal**.

Remind the user to keep `$EXPRESS_SERVER_URL` open in a browser tab — screenshots, image export, mermaid conversion, and viewport control render in the frontend (CLI exits with code 4 when no tab is connected; `status` shows the browser-client count).

### CLI Quick Reference

Results are JSON on stdout — except `describe` (plain text) and raw-content output when `--out` is omitted (`export` scene JSON, `screenshot --format svg`). Diagnostics on stderr. Exit codes: 0 ok, 1 error, 2 usage, 3 canvas unreachable, 4 browser tab required.

| Task | Command |
|------|---------|
| Inspect server | `status` (don't `start`/`stop` the shared server) |
| Create elements (batch) | `add elements.json` or `echo '[...]' \| add` or `add --one '{...}'` |
| Multi-op patch in one call | `apply patch.json` — `{"create":[...],"update":[{"id":"a","set":{...}}],"delete":[...]}` |
| Read one / query many | `get <id>`, `query [--type t] [--bbox x0,y0,x1,y1] [--filter k=v] [--filter-json '{...}']` |
| Update / delete | `update <id> --set '{...}'`, `delete <id> [...]` |
| Understand the scene | `describe` (plain-text summary: ids, positions, labels, connections) |
| See the scene | `screenshot [--out f.png]` (PNG without `--out` → temp file path in JSON; SVG without `--out` → raw SVG) |
| Layout operations | `arrange align\|distribute\|group\|ungroup\|lock\|unlock\|duplicate --ids a,b,c [--to left\|horizontal\|...]` |
| Scene files | `export [--out scene.excalidraw]`, `import [scene.excalidraw|-] [--replace]` — a `.excalidraw.md` out path writes Obsidian's format (see File I/O) |
| Mermaid → canvas | `mermaid [diagram.mmd|-]` (or stdin) |
| Snapshots | `snapshot save\|list\|restore <name>` |
| Share link | `share` (encrypted upload → excalidraw.com URL) |
| Wipe canvas | `clear --yes` (only when the user asks — the canvas is shared) |
| Find / place logos & icons | `excalidraw-icon search <query>`, `excalidraw-icon add <ref> --x --y --label` (separate command, see Icons & Logos) |
| Connect elements (elbow arrows) | `excalidraw-connect <from-id> <to-id> --label '(1) ...' --color '#1971c2'` or `excalidraw-connect -` with a JSON array (separate command) |

### Element Format (CLI and MCP)

The CLI and MCP tools accept the same agent-friendly format and normalize it automatically:

- **Labels**: put `"text": "My Label"` on any shape — converted to Excalidraw's bound-label format for you. This shorthand always renders in the default handwritten font; for monospace labels use a bound text element instead (see Architecture conventions → Labeled boxes).
- **Arrow binding**: `"startElementId": "a"` / `"endElementId": "b"` — the server always draws these as **straight diagonal** lines, even with `"elbowed": true`. For architecture diagrams use `excalidraw-connect` instead.
- **fontFamily**: pass a string name (`"helvetica"`, `"cascadia"`, `"excalifont"`, ...) or string number `"1"`–`"8"`.
- **points**: both `[[x,y], ...]` tuples and `[{"x":..,"y":..}]` objects are accepted.
- **Patch updates**: in `apply`, update entries can use either direct fields (`{"id":"a","x":120}`) or a `set` object (`{"id":"a","set":{"x":120}}`). Do not mix both forms in one update entry.

**Raw REST is stricter**: labels must be `"label": {"text": "..."}`, bindings must be `"start": {"id": "..."}` / `"end": {"id": "..."}`. Only worry about this when POSTing to the API directly.

---

## Coordinate System

The canvas uses a 2D coordinate grid: **(0, 0) is the origin**, **x increases rightward**, **y increases downward**. Plan your layout before writing any JSON.

**General spacing guidelines:**
- Vertical spacing between tiers: 80–120px (enough that arrows don't crowd labels)
- Horizontal spacing between siblings: 40–60px minimum; give labeled arrows 120px+
- Shape width: `max(160, labelCharCount * 12)` to keep the label on one line
- Shape height: 60px single-line, 80px two-line labels
- Background/zone padding: 50px on all sides around contained elements

**Styling for a professional look:**
- `"fillStyle": "solid"` on shapes gives crisp flat fills — the default is a sketchy hachure pattern
- Pair pastel `backgroundColor` fills with their darker `strokeColor` (palette in the cheatsheet)
- `"strokeStyle": "dashed"` on zone borders and async arrows reads as "boundary / background"

---

## Architecture Diagram Conventions (Required)

Apply these rules to every system / platform / pipeline / infrastructure diagram. They take precedence over the generic anti-patterns below. Reference example: `references/example-ml-platform.png` (an MLOps platform) — view it before drawing a large architecture diagram. Where the example is looser than the rules (not every arrow is numbered), follow the rules.

### Rule 1: Every main component is a deployable unit

- Top-level boxes are things you can deploy and run on their own: services, databases, message brokers, schedulers, UIs, jobs. Examples: Kafka, Schema Registry, Debezium, Spark job, Redis, PostgreSQL, Ray Serve, MLflow, NGINX, Airflow, Jupyter, SigNoz, OpenTelemetry Collector.
- Libraries, SDKs, frameworks, and concepts are **not** components. The Feast SDK can't be deployed, so it is not a box — draw what it talks to (Redis as the online store, PostgreSQL as the offline store) or the service that embeds it. Same for pandas, LangChain, an ML framework, or "feature engineering".
- Things that live *inside* a deployable unit go inside or attached to that unit, never as free-standing peers:
  - Kafka topics → pill/cylinder shapes carrying the Kafka logo.
  - Airflow DAG tasks → boxes inside a dashed boundary with the Airflow logo in its corner.
  - Model replicas (XGBoost) → boxes inside the Ray Serve box.
  - Buckets/tables → labeled under their store's logo ("Model Storage" on MinIO, "Metric Storage" on PostgreSQL).
- Label by role, with the technology shown by its logo: "Online Store" under the Redis logo, "Offline Store" under the PostgreSQL logo.
- Self-check each top-level box: "could I `docker run` / `helm install` this?" If not, fold it into its host or remove it.

### Rule 2: Arrows follow the flow of data

- If data moves from A to B, the arrow goes **A → B**, and its label names the data or action ("logs", "features", "latest model").
- Direction follows the data even when B initiates: if the training job pulls features from the offline store, draw Offline Store → Training labeled "pull features"; Ray Serve loading a model is MLflow → Ray Serve labeled "load latest model".
- If A only calls/triggers B and no meaningful data moves, the arrow goes **A → B** (caller → callee), labeled with the action ("trigger", "invoke").
- No double-headed arrows for request/response — draw the direction of the primary payload.

### Rule 3: Every arrow has a description and a step number

- Label format: `(n) description`, e.g. `(1) send logs`, `(3) validate`, `(4) push features`. Keep descriptions to 1–4 words; the label sits on the arrow (`excalidraw-connect --label`).
- Numbers follow the order events happen. Parallel/alternative branches of one step use sub-numbers: `(2.1) cdc`, `(2.2) push`. A fan-out of the same step may repeat its number (three `(4)` arrows leaving Spark in the example).
- **Multiple user flows** (end user vs. developer, serving vs. training): give each flow its own arrow color and its **own numbering starting at 1** — e.g. end-user flow `(1)…(5)` in blue and developer flow `(1)…(6)` in green. Set the color via the arrow's `strokeColor` (its label inherits it automatically), and add a small legend (short colored arrow + flow name) in a corner.
- Suggested flow colors: end user / serving `#1971c2` (blue), developer / training `#2f9e44` (green), data ingestion `#e8590c` (orange), ops `#9c36b5` (purple). Keep one flow per color across the whole diagram.

### Rule 4: Solid arrows by default; dashed arrows are rare

- Main flows — anything directly on a user's path (end-user requests, developer workflow) — are solid.
- Use `"strokeStyle": "dashed"` only for secondary/background flows not directly tied to a user: telemetry and log collection, alerting, async replication, periodic sync, backups. If more than ~20% of arrows are dashed, reconsider.
- Dashed *zone borders* are fine; this rule is about arrows.

### Rule 5: Icons everywhere, and big

- **Always prefer an icon over a plain box.** Every deployable unit gets its product logo; every actor gets a person/device icon (`mdi:account`, `mdi:laptop-account`, `mdi:cellphone`); generic components get a generic icon (`mdi:server`, `mdi:database`, `mdi:api`, `mdi:web`, `mdi:cloud`, `mdi:file-document`, `mdi:bucket`). Search before giving up: `excalidraw-icon search <name>` checks svgl and all Iconify sets (`logos:`, `selfhst:`, `devicon:`, `simple-icons:`, `mdi:`).
- A plain box is only acceptable for things inside a unit that no icon represents (DAG task steps, "train final model") — and even then, a small logo of the host tool next to the box helps (the example puts the Ray logo under "train final model").
- **Size**: main components 96px (the `excalidraw-icon` default); the central/most important unit may be 120–140px; secondary items (storage buckets, sidecars, logos next to boxes) 48–64px. Never below 48px. Monochrome icons: pass `--color` matching their flow or zone.
- Label every icon with its role (`--label "Online Store"`); the technology is conveyed by the logo.

### Rule 6: Arrows are always orthogonal (elbow)

- Every arrow is made of horizontal and vertical segments only — no diagonals, no curves. Draw them with `excalidraw-connect` (see **Arrows: Always Orthogonal**), which routes elbows, binds both ends, and adds the numbered label.
- Don't use `startElementId`/`endElementId` in `add` for architecture diagrams: the server renders those as straight diagonals.
- Prefer layouts where connected components share a row or column so arrows are straight lines; `excalidraw-connect` snaps to a straight segment whenever the two sides overlap.

### Layout & style (from the reference example)

- **Zones by lifecycle stage**: group components into zones such as Data Pipeline, Serving Pipeline, Training Pipeline, Dev Env, Model Registry, Observability. Each zone: pastel fill, thin dashed border, title as a free-standing text at the top-left (fontSize 24–28). Fills used in the example: `#e7f5ff` blue, `#fff4e6` orange, `#ebfbee` green, `#fff9db` yellow, `#f1f3f5` gray.
- **Components are big icons first** (see Rule 5): each deployable unit is its logo, placed with `excalidraw-icon` at 96px (default) with its role label underneath — "Online Store" under `logos:redis`, "Offline Store" under `logos:postgresql`. Use a white rounded box only for things with no sensible icon (internal steps like "quality check").
- **Replicas**: draw 2–3 copies with "..." between them (Producer 1, Producer 2, ..., Producer N).
- **Actors**: an icon (e.g. `mdi:account`, `mdi:laptop-account`) where each user flow starts.
- **Orchestrators** (Airflow, Argo Workflows): a dashed boundary around the tasks they run, orchestrator logo at the boundary's top-right; sub-steps can sit in their own tinted sub-zones.
- **Clean technical look**: `"roughness": 0`, `"fontFamily": "cascadia"` (monospace) for all text, `"fillStyle": "solid"`, strokeWidth 1–2.
- **Labeled boxes (monospace)**: the `"text"` shorthand on shapes renders in the handwritten font regardless of `fontFamily`. Create the label as a bound text element instead — the shape lists it in `boundElements`, the text points back via `containerId`:
  ```json
  [
    {"id": "qc", "type": "rectangle", "x": 700, "y": 620, "width": 200, "height": 70, "roughness": 0, "roundness": {"type": 3}, "backgroundColor": "#ffffff", "fillStyle": "solid", "boundElements": [{"id": "qc-text", "type": "text"}]},
    {"id": "qc-text", "type": "text", "x": 710, "y": 643, "width": 180, "height": 24, "text": "quality check", "fontSize": 18, "fontFamily": "cascadia", "textAlign": "center", "verticalAlign": "middle", "containerId": "qc"}
  ]
  ```
  `excalidraw-icon` labels and `excalidraw-connect` arrow labels are already monospace.
- **Routing**: all arrows orthogonal via `excalidraw-connect` (Rule 6). Cross-zone arrows are expected — leave 60–100px gutters between zones and pass `viaX`/`viaY` so the middle segment runs through a gutter, never across another zone.

### Planning an architecture diagram

Before writing any JSON, write down:
1. The deployable units (Rule 1) and which zone each belongs to.
2. Each user flow, its color, and its ordered steps as `(n) source → target: description` (Rules 2–3).
3. Which arrows (if any) are secondary and dashed (Rule 4).

4. The icon ref for every component (`excalidraw-icon search`) — aim for an icon on every deployable unit and actor (Rule 5).

Then:
1. Draw zones (rectangles + free-standing titles) in reading order (left → right, top → bottom following flow `(1)`), sized for 96px icons with ~180px spacing.
2. Place all components with one `excalidraw-icon add -` batch, giving each a stable `id`.
3. Draw each flow's arrows with one `excalidraw-connect -` batch per flow (or all at once), in step order.
4. Add a legend (one short `excalidraw-connect` sample per flow, or colored text) if there are multiple flows.
5. `screenshot` and run the Quality Checklist; fix crossings with `fromSide`/`toSide`/`viaX`/`viaY` by deleting and re-connecting the arrow.

---

## Layout Anti-Patterns (Critical for Complex Diagrams)

These are the most common mistakes that produce unreadable diagrams. Avoid all of them.

### 1. Do NOT use `label.text` (or `text`) on large background zone rectangles

When you put a label on a background rectangle, Excalidraw creates a bound text element centered in the middle of that shape — right where your service boxes will be placed. The text overlaps everything inside the zone and cannot be repositioned.

**Wrong:**
```json
{"id": "vpc-zone", "type": "rectangle", "x": 50, "y": 50, "width": 800, "height": 400, "text": "VPC (10.0.0.0/16)"}
```

**Right — use a free-standing text element anchored at the top of the zone:**
```json
{"id": "vpc-zone", "type": "rectangle", "x": 50, "y": 50, "width": 800, "height": 400, "backgroundColor": "#e3f2fd"},
{"id": "vpc-label", "type": "text", "x": 70, "y": 60, "width": 300, "height": 30, "text": "VPC (10.0.0.0/16)", "fontSize": 18}
```

The free-standing text element sits at the top corner of the zone and doesn't interfere with elements placed inside.

### 2. Avoid cross-zone arrows in complex diagrams

An arrow from an element in one layout zone to an element in a distant zone will draw a long diagonal line crossing through everything in between. In a multi-zone infra diagram this produces an unreadable tangle of spaghetti.

**Design rule:** Keep arrows within the same zone or tier. To show cross-zone relationships, use annotation text or separate the zones so their edges are adjacent (no elements between them), and route the arrow along the edge.

If you must connect across zones, use an elbowed arrow that travels along the perimeter — never through the middle of another zone.

**Architecture diagrams:** cross-zone arrows are normal (data flows between pipelines) — route them through gutters between zones as described in Architecture Diagram Conventions.

### 3. Use arrow labels sparingly

Arrow labels are placed at the midpoint of the arrow. On short arrows, they overlap the shapes at both ends. On crowded diagrams, they collide with nearby elements.

- Only add an arrow label when the relationship name is genuinely essential (e.g., protocol, port number, data direction).
- If you're adding a label to every arrow, reconsider — it usually adds visual noise, not clarity.
- Keep arrow labels to ≤ 12 characters. Prefer omitting them entirely on dense diagrams.

**Architecture diagrams override this:** every arrow gets a short numbered label (`(n) description`, Rule 3). Keep them short, and make arrows long enough (≥ 120px) that labels don't touch the shapes at either end.

---

## Quality: Why It Matters (and How to Check)

Excalidraw diagrams are visual communication. If text is cut off, elements overlap, or arrows cross through unrelated shapes, the diagram becomes confusing and unprofessional — it defeats the whole purpose of drawing it. So after every batch of elements, verify before adding more.

### Quality Checklist

After each `add` / `apply` / `batch_create_elements`, take a screenshot and check:

1. **Text truncation** — Is all label text fully visible? Truncated text means the shape is too small. Increase `width` and/or `height`.
2. **Overlap** — Do any shapes share the same space? Background zones must fully contain children with padding.
3. **Arrow crossing** — Do arrows cut through unrelated elements? If yes, re-connect them with different sides or `viaX`/`viaY` (see Arrow Routing below).
4. **Arrow-label overlap** — Arrow labels sit at the midpoint. If they overlap a shape, shorten the label or adjust the arrow path.
5. **Spacing** — At least 40px gap between elements. Cramped layouts are hard to read.
6. **Readability** — Font size ≥ 16 for body text, ≥ 20 for titles.
7. **Zone label placement** — If you used `text`/`label.text` on a background zone rectangle, the zone label will be centered in the middle of the zone, overlapping everything inside. Fix: delete the bound text element and add a free-standing text element at the top of the zone instead (see Layout Anti-Patterns above).

For architecture diagrams, also check the conventions:

8. **Deployable units** — every top-level box is deployable; no SDK/library boxes (Rule 1).
9. **Arrow direction** — every arrow points the way data moves, or caller → callee if no data moves (Rule 2).
10. **Numbering** — every arrow has `(n) description`; each flow has its own color and numbering from 1, with a legend if there's more than one flow (Rule 3).
11. **Dashed arrows** — only on secondary, non-user flows (Rule 4).
12. **Icons** — every component and actor that can have an icon has one, at 96px (48–64px for secondary items) (Rule 5).
13. **Orthogonal arrows** — no diagonal or curved arrows; nothing crosses an icon, label, or unrelated zone (Rule 6).

If you find any issue: **stop, fix it, re-screenshot, then continue.** Say "I see [issue], fixing it" rather than glossing over problems. Only proceed once all checks pass.

---

## Workflow: Drawing a New Diagram

### Mermaid vs. Direct Creation — Which to Use?

**Use `mermaid` / `create_from_mermaid`** when: the user already has a Mermaid diagram, or the structure maps cleanly to a flowchart/sequence/ER diagram with standard Mermaid syntax. It's fast and handles conversion automatically, though you get less control over exact layout.

**Create elements directly** when: you need precise layout control, the diagram type doesn't map to Mermaid well (e.g., custom architecture, annotated cloud diagrams), or you want elements positioned in a specific coordinate grid.

### Steps (CLI shown; MCP tools are 1:1 — see cheatsheet)

1. Plan your coordinate grid — map out tiers and x-positions before writing JSON. (MCP mode: call `read_diagram_guide` for colors/sizing; the same guidance lives in `references/cheatsheet.md`.)
2. `describe` to see what's already on the shared canvas. If it holds unrelated work, `snapshot save <name>` and ask before `clear --yes`, or draw in empty space away from it.
3. Place components as icons in one call, with custom `id`s for connecting and later updates:
   ```bash
   excalidraw-icon add - <<'EOF'
   [
     {"ref": "logos:nginx",      "x": 300, "y": 40,  "label": "Load Balancer", "id": "lb"},
     {"ref": "mdi:server",       "x": 100, "y": 240, "label": "Web Server 1",  "id": "svc-a", "color": "#1971c2"},
     {"ref": "mdi:server",       "x": 500, "y": 240, "label": "Web Server 2",  "id": "svc-b", "color": "#1971c2"},
     {"ref": "logos:postgresql", "x": 300, "y": 440, "label": "Database",      "id": "db"}
   ]
   EOF
   ```
4. Connect them with orthogonal arrows in one call:
   ```bash
   excalidraw-connect - <<'EOF'
   [
     {"from": "lb",    "to": "svc-a", "label": "(1) route", "fromSide": "bottom", "toSide": "top"},
     {"from": "lb",    "to": "svc-b", "label": "(1) route", "fromSide": "bottom", "toSide": "top"},
     {"from": "svc-a", "to": "db",    "label": "(2) query", "fromSide": "bottom", "toSide": "top"},
     {"from": "svc-b", "to": "db",    "label": "(2) query", "fromSide": "bottom", "toSide": "top"}
   ]
   EOF
   ```
5. Only use plain shapes (via `add`) for things no icon represents; size them `max(160, labelLength * 12)` wide.
6. `screenshot` → view the file → run the Quality Checklist → fix issues before the next batch.

---

## Arrow Routing — Avoid Overlaps

All arrows are orthogonal (elbow) — no curves, no diagonals. Use `excalidraw-connect` (see **Arrows: Always Orthogonal**); it handles fan-out by spreading arrows along a side and snaps to straight segments when sides line up.

- **Fan-out** (one source → many targets): connect them in one batch so exit points are spread; arrange targets in a column (source `right` → targets `left`).
- **Cross-lane / cross-zone**: set `viaX` / `viaY` to a gutter coordinate so the middle segment runs between zones.
- **Obstacle in the way**: change `fromSide`/`toSide` (e.g. exit `bottom`, enter `left`) or move the middle segment with `viaX`/`viaY`.

If you must hand-write an arrow (no endpoints to bind to), use `"elbowed": true` with explicit points where every segment is horizontal or vertical — and no `startElementId`/`endElementId` (those force a straight diagonal):
```json
{"type": "arrow", "x": 100, "y": 100, "points": [[0, 0], [120, 0], [120, 80], [240, 80]], "elbowed": true, "roughness": 0}
```

**Rule:** If an arrow would pass through an unrelated shape, re-route it — never leave a crossing.

---

## Arrows: Always Orthogonal (`excalidraw-connect`)

`excalidraw-connect` draws elbow arrows between existing elements (by id): horizontal/vertical segments only, bound to both ends (they follow shapes dragged in the browser), with a monospace label colored like the arrow.

```bash
# one arrow
excalidraw-connect user nginx --label "(1) send id" --color "#1971c2"

# a whole flow in one call (preferred — arrows sharing a side get spread out)
excalidraw-connect - <<'EOF'
[
  {"from": "user",  "to": "nginx", "label": "(1) send id",  "color": "#1971c2"},
  {"from": "nginx", "to": "serve", "label": "(2) predict",  "color": "#1971c2"},
  {"from": "redis", "to": "serve", "label": "(3) features", "color": "#1971c2", "toSide": "top"},
  {"from": "serve", "to": "otel",  "label": "traces",       "color": "#868e96", "dashed": true, "viaY": 620}
]
EOF
```

Spec fields / flags:
- `from`, `to` — element ids (icons: the icon id, not the `-label`). Direction = data flow (Rule 2).
- `label` — `(n) description` (Rule 3). `color` — flow color. `dashed` — secondary flows only (Rule 4).
- `fromSide` / `toSide` (`--from-side` / `--to-side`) — `right|left|top|bottom`. Auto: horizontal gap → right/left, otherwise bottom/top. Icon labels are accounted for, so `bottom` exits below the label.
- `viaX` / `viaY` (`--via-x` / `--via-y`) — coordinate of the middle segment; use it to route through the gutter between zones or around an obstacle.
- `id` — arrow id (default `arrow-<from>-<to>-<rand>`); its label is `<id>-label`.

Behavior and gotchas:
- The router does not avoid obstacles. After drawing, `screenshot`; if an arrow crosses an element or label, delete it (and its `-label`) and re-connect with `fromSide`/`toSide`/`viaX`/`viaY`.
- Draw arrows that share an element side in the **same call** so they're spread along that side. The output includes `warnings` when a side already has arrows from an earlier call — then pick a free side.
- Moving elements via `update`/`arrange` does not re-route these arrows; delete and re-connect them. (Dragging in the browser does re-route.)

---

## Icons & Logos (`excalidraw-icon`)

Use real logos/icons for every component you can (Rule 5) — services, tools, infrastructure, actors, generic resources. The `excalidraw-icon` command fetches SVGs and places them on the canvas as image elements — the SVG never passes through your context, so don't try to embed SVGs via MCP `import_scene` yourself.

**Sources / refs:**
- **svgl** (`svgl:<slug>`) — ~670 colorful brand logos. Many have `light`/`dark` variants; the canvas is light-themed by default, so use the `light` ref. Wordmarks (logo + name) are listed separately.
- **Iconify** (`<prefix>:<name>`) — 200k+ icons. Useful sets: `logos:` (color brand logos), `selfhst:` (self-hosted/homelab apps: proxmox, jellyfin, traefik, ...), `simple-icons:` (monochrome brands), `devicon:` (dev tools/languages), `mdi:` / `lucide:` / `tabler:` (generic UI icons: server, database, user, cloud). Monochrome sets accept `--color`.

**Workflow:**
1. Find refs (JSON out): `excalidraw-icon search docker` — searches svgl + Iconify; narrow with `--source svgl|iconify` or `--prefix selfhst,logos`. Iconify search is keyword-based ("database", not "place to store data").
2. Place one: `excalidraw-icon add svgl:docker --x 100 --y 100 --label Docker [--size 96] [--id docker]`
3. Place many in one call (preferred):
   ```bash
   excalidraw-icon add - <<'EOF'
   [
     {"ref": "selfhst:proxmox", "x": 100, "y": 100, "label": "Proxmox", "id": "pve"},
     {"ref": "logos:kubernetes", "x": 260, "y": 100, "label": "Talos k8s", "id": "k8s"},
     {"ref": "mdi:database", "x": 420, "y": 100, "color": "#2f9e44", "label": "Postgres"},
     {"ref": "selfhst:minio", "x": 580, "y": 120, "size": 56, "label": "Model Storage"}
   ]
   EOF
   ```
4. Output lists each `id`, `labelId`, and the final `width`/`height` (aspect ratio preserved, longest side = `size`, default 96). The label is a separate monospace text element (18px) centered 8px below the icon — budget ~35px of vertical space for it.
5. Connect with `excalidraw-connect` using the returned ids, then `screenshot` to verify as usual. Icons are regular elements: move/resize with `update`, remove with `delete` (delete the `-label` element too).

**Layout tips:** 96px icons need ~180px horizontal spacing (label width + a labeled arrow between them) and ~170px vertical spacing; for icons inside a zone or a node box, place the icon at the top-left of the box and put text beside it rather than stacking labels on top. `excalidraw-icon svg <ref> --out file.svg` saves the normalized SVG for use outside the canvas (docs, READMEs).

---

## Workflow: Iterative Refinement

Pairing `describe` with `screenshot` is what makes this skill powerful.

- **`describe`** (`describe_scene` in MCP) → structured text: element IDs, types, positions, labels, connections. Use it to know *what's on the canvas* before making programmatic updates (find IDs, understand bounding boxes).
- **`screenshot`** (`get_canvas_screenshot` in MCP) → PNG of the actual rendered canvas. Use it for *visual quality verification* — it shows exactly what the user sees, including truncation, overlap, and arrow routing. The CLI prints the saved file path as JSON; read/view that file.

**Feedback loop:**
```
add elements
  → screenshot → view → "text truncated on auth-svc"
  → update auth-svc --set '{"width": 220}' → screenshot → "overlap between auth-svc and rate-limiter"
  → update rate-limiter --set '{"x": 520}' → screenshot → "all checks pass"
  → proceed
```

## Workflow: Refine an Existing Diagram

1. `describe` to understand current state — note element IDs and positions.
2. Identify elements by `id` or label text (not by x/y coordinates — they change).
3. `update <id> --set '{...}'` to resize/recolor/move; `delete <id>` to remove; or bundle everything in one `apply` patch. **Bound arrows re-route automatically when you move or resize their endpoints** — no need to delete and recreate them.
4. `screenshot` to confirm the change looks right.
5. If updates fail: check the ID exists with `get <id>`; unlock with `arrange unlock --ids <id>` if locked.

## Workflow: Mermaid Conversion

```bash
echo 'graph TD
  A[Client] --> B[API]
  B --> C[(DB)]' | npx -y mcp-excalidraw-server@2.1.2 mermaid
```
Requires an open browser tab (conversion runs in the frontend; exit code 4 tells you to open the canvas URL). Afterwards `screenshot` to verify layout. If the auto-layout is poor (nodes crowded, edges crossing), find problem elements with `describe` and reposition them with `update`.

## Workflow: File I/O

- Export scene: `export --out diagram.excalidraw` (no `--out` → JSON to stdout)
- Import scene: `import diagram.excalidraw` (append) or `import diagram.excalidraw --replace`
- Image: `screenshot --out diagram.png` / `screenshot --format svg --out diagram.svg` (browser tab required)
- Share link: `share` — encrypts the scene and returns a shareable excalidraw.com URL

This is how diagrams live in a repo: commit the `.excalidraw` file, and re-`import` + edit + `export` it when the architecture changes.

### Obsidian vaults: use `.excalidraw.md`

Check the destination before writing: if any ancestor directory contains `.obsidian/`, it is an Obsidian vault. A raw `.excalidraw` file there opens in the Excalidraw plugin only in **compatibility mode** ("Convert to new format" warning), gets no block references or vault-wide search, and default Obsidian Sync skips non-`.md` files. Give the export a `.excalidraw.md` extension and the CLI writes the plugin's native format automatically:

```bash
npx -y mcp-excalidraw-server@2.1.2 export --out "$VAULT/diagrams/system-map.excalidraw.md"   # .md → Obsidian format (or force with --format obsidian)
npx -y mcp-excalidraw-server@2.1.2 import "$VAULT/diagrams/system-map.excalidraw.md" --replace  # reads both plain and compressed Drawing blocks
```

Round-trips are safe: text-element block references follow the plugin's own id rules, so re-importing, editing, and re-exporting the same file keeps links from other notes intact.

## Workflow: Snapshots

1. `snapshot save <name>` before risky changes.
2. Make changes, evaluate with `describe` / `screenshot`.
3. `snapshot restore <name>` to roll back if needed. `snapshot list` shows what's saved.

## Workflow: Duplication

`arrange duplicate --ids a,b --offset 40,40` (default offset 20,20). Useful for repeated patterns or copying layouts.

## Error Recovery

- **Exit code 3 (canvas unreachable)?** Check `echo $EXPRESS_SERVER_URL` and `curl -s $EXPRESS_SERVER_URL/health`. The shared server requires LAN/VPN access; if it's down, tell the user (`sudo systemctl status docker-excalidraw` on the server) — do not `start` a local canvas.
- **Exit code 4 (browser required)?** Ask the user to open `$EXPRESS_SERVER_URL` in a browser, then retry — screenshots, image export, viewport, and mermaid conversion render in the frontend.
- **Elements not appearing?** Check `describe` — they may be off-screen. In MCP mode, use `set_viewport` with `scrollToContent: true`, or `scrollToElementIds` plus optional `viewportZoomFactor` to focus on a specific subgraph; in a browser, press the zoom-to-fit button.
- **Arrow not connecting?** Verify element IDs with `get <id>` (for icons, connect the icon id, not its `-label`). `excalidraw-connect` exits 2 with "element not found" for bad ids.
- **Canvas in a bad state?** `snapshot save` first, then `clear --yes` and rebuild. Or `snapshot restore` to go back.
- **Element won't update?** It may be locked — `arrange unlock --ids <id>` first.
- **Duplicate text elements / element count doubling?** The frontend auto-sync timer periodically writes the full Excalidraw scene back to the server. Excalidraw internally generates a bound text element for every shape with a label; clearing and re-sending elements can re-inject cached bound texts. Clean up: `query --type text` to find elements with a `containerId`, `delete` the unwanted ones, wait a few seconds for auto-sync to settle. The safest prevention: **never put labels on background zone rectangles** — use free-standing text elements.

---

## References

- `references/example-ml-platform.png`: reference architecture diagram (MLOps platform) showing zones, deployable units with logos, replicas, orchestrator boundaries, and numbered data-flow arrows.
- `references/cheatsheet.md`: full CLI reference, the 26 MCP tools, REST API endpoints + payload shapes, and the diagram design guide (colors, sizing).
