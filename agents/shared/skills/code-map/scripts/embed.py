#!/usr/bin/env python3
"""Render a code-map: embed one or more JSON graph models into the canvas template.

usage: embed.py --title "Map title" --out map.html model1.json [model2.json ...]
Each model becomes a tab (its "provider" field is the tab label).
"""
import argparse, json, pathlib, sys

TEMPLATE = pathlib.Path(__file__).resolve().parent.parent / "assets" / "template.html"

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--title", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("models", nargs="+")
    a = ap.parse_args()
    html = TEMPLATE.read_text()
    tags = []
    for i, path in enumerate(a.models):
        model = json.loads(pathlib.Path(path).read_text())
        for key in ("provider", "chapters", "nodes", "edges"):
            if key not in model:
                sys.exit(f"{path}: missing '{key}'")
        ids = {n["id"] for n in model["nodes"]}
        bad = [e for e in model["edges"] if e["from"] not in ids or e["to"] not in ids]
        if bad:
            sys.exit(f"{path}: {len(bad)} edges reference unknown nodes")
        data = json.dumps(model, ensure_ascii=False).replace("</", "<\\/")
        tags.append(f'<script type="application/json" data-model id="model-{i}">{data}</script>')
    html = html.replace("<!--MODELS-->", "\n  ".join(tags), 1).replace("{{TITLE}}", a.title)
    pathlib.Path(a.out).write_text(html)
    print(f"wrote {a.out}: {len(tags)} tab(s)")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
