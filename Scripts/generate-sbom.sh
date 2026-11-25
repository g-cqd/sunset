#!/usr/bin/env bash
# Generates a CycloneDX 1.5 JSON SBOM for Sunset from Package.resolved plus Engine/WebKit/base & patches (N-S7).
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: $0 <version> <output-path>" >&2
  exit 2
fi

VERSION="$1"
OUTPUT="$2"

python3 - "$VERSION" "$OUTPUT" <<'PY'
import json
import os
import sys
from pathlib import Path
from urllib.parse import urlparse

version = sys.argv[1]
output = Path(sys.argv[2])

components = []

# 1. SwiftPM dependencies from Package.resolved
resolved_path = Path("Package.resolved")
if resolved_path.is_file():
    resolved = json.loads(resolved_path.read_text(encoding="utf-8"))
    for pin in sorted(resolved.get("pins", []), key=lambda p: p.get("identity", "")):
        identity = pin.get("identity", "")
        location = pin.get("location", "")
        state = pin.get("state", {})
        ver = state.get("version") or state.get("revision") or state.get("branch") or "unknown"
        parsed = urlparse(location)
        if parsed.netloc.lower() == "github.com":
            parts = [p for p in parsed.path.split("/") if p]
            if len(parts) >= 2:
                repo = parts[1][:-4] if parts[1].endswith(".git") else parts[1]
                purl = f"pkg:swift/github.com/{parts[0]}/{repo}@{ver}"
            else:
                purl = f"pkg:swift/{identity}@{ver}"
        else:
            purl = f"pkg:swift/{identity}@{ver}"
        components.append({
            "type": "library",
            "name": identity,
            "version": ver,
            "purl": purl,
            "externalReferences": [{"type": "vcs", "url": location}],
        })

# 2. Bundled Sunset WebKit engine base revision + patch series
base_path = Path("Engine/WebKit/base")
if base_path.is_file():
    wk_rev = base_path.read_text(encoding="utf-8").strip().splitlines()[0].strip()
    patches_dir = Path("Engine/WebKit/patches")
    patches = sorted(p.name for p in patches_dir.glob("*.patch")) if patches_dir.is_dir() else []
    components.append({
        "type": "framework",
        "name": "WebKit",
        "version": wk_rev,
        "purl": f"pkg:github/WebKit/WebKit@{wk_rev}",
        "externalReferences": [{"type": "vcs", "url": "https://github.com/WebKit/WebKit"}],
        "properties": [
            {"name": "sunset:webkit-patch-count", "value": str(len(patches))},
            {"name": "sunset:webkit-patches", "value": ",".join(patches)},
        ],
    })

doc = {
    "bomFormat": "CycloneDX",
    "specVersion": "1.5",
    "version": 1,
    "metadata": {
        "component": {
            "type": "application",
            "name": "Sunset",
            "version": version,
        }
    },
    "components": components,
}

output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(doc, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
