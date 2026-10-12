---
name: code-map
description: Build an interactive, code-referenced map of a system (pipeline, architecture, request flow, data lineage) as a full-screen Palantir-style object canvas. Uniform pseudo-3D cubes, right-angled connectors, a left-to-right two-lane snake, big chapter zones with plain-language summaries, hover cards, and click-to-copy path:line. Use when the user wants to visualise, explore or understand code or architecture ("map the pipeline", "show me how X flows", "diagram this system").
---

# code-map

Produces one self-contained HTML file (works from `file://`, no network) that lets a non-reader of the code explore a system: what runs, in what order, what runs in parallel, what each step reads and writes, and where it lives in the code.

The look and behaviour are fixed by `assets/template.html`. **Don't redesign it.** It is the result of several owner feedback rounds. Your job is to produce an accurate graph model and render it with the template.

## Pipeline (four stages, each a separate agent run)

1. **Extract** (`prompts/1-extract.md`, adapted to the target system).
   A strong code-reading model (e.g. Codex Sol) reads the code read-only and writes one JSON model per view (tab).
   - Every node carries a `code` reference (`repo/relative/path.py:LINE`), checked with `sed -n` before it is written.
   - No HTML at this stage.
2. **Adversarial verify** (`prompts/2-verify.md`). A **fresh** run assumes the model is wrong and checks every node against the code:
   - parameters, parallelism, retries, drops and tokenisation, identities, table columns from the migrations, order, and missing nodes.
   - It fixes the JSON in place and writes `REVIEW.md` (corrections with evidence).
   - The first draft is usually substantially wrong: the reference run corrected 119 nodes out of 198. Never skip this stage.
   - Feed it any facts measured at runtime; they beat code-reading inferences.
3. **Plain language** (`prompts/3-plain-language.md`). Adds `plain` to every node and chapter: 1–3 very simple, **business-level** sentences.
   - Say where we are in the journey, why the step exists for the business, what problem it prevents, and how it links to the previous and next step.
   - Written only from the verified model.
   - Known issues are stated plainly.
4. **Render:**
   `python3 scripts/embed.py --title "<Map title>" --out <out>.html model-a.json [model-b.json …]`
   - Each model becomes a tab; its `provider` field is the tab label.
   - Then open it in the browser.

The stages can be parallelised across different views. To change only the presentation later, re-run `embed.py`; never regenerate the content.

## Model schema (`references` = this section)

```json
{
  "provider": "Tab label", "code_ref": "branch/commit the map describes",
  "overview": "one paragraph",
  "chapters": [{"id": "capture", "title": "3. HTTP capture", "summary": "technical", "plain": "2-3 simple sentences"}],
  "nodes": [{"id": "n1", "chapter": "capture",
             "type": "step|endpoint|transform|domain|table|engine",
             "title": "short label", "rank": 7,
             "details": {"Key": "plain-English value"},
             "plain": "business-level explanation",
             "code": "backend/app/x.py:42"}],
  "edges": [{"from": "n1", "to": "n2", "label": "optional"}]
}
```
- `rank` is chronological order; nodes sharing a rank run in parallel and are drawn as a vertical stack.
- Keep each map readable at about 40–110 nodes per view. Group repetitive items, e.g. one node per endpoint family, with the variants listed in the details.
- Remap `type` meanings for non-ETL maps (e.g. endpoint becomes route, table becomes store), but keep the six type keys, because the template colours by them.

## The style (owner-approved, binding)

- **Full-screen infinite canvas:** pan by dragging, cursor-centred zoom, Fit/Reset, a minimap, light/dark themes (dark default).
- **Every node is the same-size orthographic pseudo-3D cube** (172×108 with extrusion). Never variable-height bricks or columns.
- **Text inside cubes:**
  - the title wraps onto up to 3 lines, never ellipsised mid-word;
  - then up to 3 single-line "name · value" rows;
  - then "+N more".
  - No text may be cut by the cube's edge.
  - Text stays visible at every zoom: no blank blocks.
- **Connectors are orthogonal only:** right angles, arrowheads, no crossings within a zone.
- **Layout runs left to right.** Sequential steps **snake between two lanes** (upper/lower, offset about half a cube), which keeps the width to roughly 0.65–0.7× a straight lane. Real parallel siblings stay vertical stacks. Each cube carries a step number (`chapter.step`).
- **Chapters are zones** with generous margins between them and padding inside. Each zone shows a **big title**, scaled inversely with zoom so it stays readable, and its `plain` summary underneath.
- **Hover panel:** a wide panel (up to 820 px) on the side of the screen away from the cube, not following the cursor. The rest of the screen dims, except the cube and the panel. It shows title and type, then a highlighted plain-language box, then details as a key | value grid, then the code reference. It re-places itself on zoom and pan, and clicking a cube closes it so the path highlight shows.
- **Click:** copies `path:line` (navigator.clipboard with a textarea fallback for `file://`), shows a toast, and highlights the upstream and downstream path.
- **Header:** title, `code_ref`, tabs, a horizontally scrolling chapter chip row (never clipped at 1280 px), search with fly-to, zoom controls, theme toggle.
- **No text selection** when dragging the canvas (`user-select: none`, except inputs).

## Rejected, don't do again

- A graph in a small container in the middle of the page.
- Variable-size bricks or columns, grid layouts for parallel groups, or "semantic zoom" that hides card text and leaves empty boxes.
- A single straight lane for long sequential chains: too wide, forcing extreme zoom-out.
- Cramped spacing and chapters without visual margins.

## Self-checks before handing over (headless Chrome)

- zero cube overlaps, extrusion included;
- every cube the same size;
- no text overflowing a cube; no title ellipsised mid-word;
- all edges orthogonal; no crossings within a zone; step numbers in order;
- the header doesn't overflow at 1280 px;
- zone titles and summaries don't overlap cubes or each other, at fit-all and at 100%. Check chapters whose first cube sits high in the zone;
- both themes render; hover and click work; no console errors; no external requests.
- Screenshot: `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --window-size=1600,900 --virtual-time-budget=4000 --screenshot=out.png file:///abs/path/map.html`

## Operating notes

- **Code-reading stages run against read-only snapshots:** e.g. a detached `git worktree add --detach <path> <ref>` per branch. Say in `code_ref` which ref each view shows.
- **Delegating the template edits to opencode:**
  - run it from the folder holding every file it needs (copy references in), because opencode rejects reads outside `--dir`;
  - give it a frozen copy to start from if another agent is editing the main file at the same time.
- **Presentation changes go into the template and are re-rendered.** Content changes go into the JSON.
- Keep the final map, the JSON models and `REVIEW.md` together in one folder per mapping.
