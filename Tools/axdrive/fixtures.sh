#!/usr/bin/env bash
# Test fixtures for on-screen checks with axdrive, written to a folder (default /tmp/sunset-fixtures, which the system may clear):
# a page server's root (article.html) and session files of web tabs. Serve with:
#   (cd "$dir/site" && python3 -m http.server 8766 --bind 127.0.0.1)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
dir="${1:-/tmp/sunset-fixtures}"
mkdir -p "$dir/site"
cp "$here/Fixtures/article.html" "$dir/site/article.html"
python3 - "$dir" <<'PY'
import json, sys, uuid
out = sys.argv[1]
def new(): return str(uuid.uuid4()).upper()
def page(i): return {"kind": "web", "pane": new(), "state": {"url": "http://127.0.0.1:8766/article.html?%d" % i}}
def session(contents, items):
    return {"favorites": {"contents": [], "favorites": {"nodes": []}}, "version": 2,
            "windows": [{"contents": contents, "workspace": {"items": items, "selected": items[0]["id"]}}]}
def single(c): return {"focused": c["pane"], "id": new(), "layout": {"pane": c["pane"]}}
# 40 article tabs.
pages = [page(i) for i in range(40)]
json.dump(session(pages, [single(c) for c in pages]), open(out + "/article-session.json", "w"))
# A horizontal split of two pages first, then 20 tabs.
a, b = page(100), page(101)
rest = [page(i) for i in range(20)]
split = {"focused": a["pane"], "id": new(),
         "layout": {"axis": "horizontal", "children": [{"pane": a["pane"]}, {"pane": b["pane"]}], "fractions": [0.5, 0.5]}}
json.dump(session([a, b] + rest, [split] + [single(c) for c in rest]), open(out + "/split-session.json", "w"))
PY
echo "$dir"
