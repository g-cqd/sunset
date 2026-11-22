#!/usr/bin/env python3
"""Gives a type a `runtime`: `python3 give-runtime.py FILE TYPE [static]`. The property goes first in the type,
at the type's access level, and the file imports SunsetRuntime at the level its declarations need."""
import re
import sys

path, name = sys.argv[1], sys.argv[2]
static = len(sys.argv) > 3 and sys.argv[3] == "static"
environment = len(sys.argv) > 3 and sys.argv[3] == "environment"
text = open(path).read()
lines = text.split("\n")
pattern = re.compile(r"^(\s*)((?:@\w+(?:\([^)]*\))?\s+)*)((?:public|package|internal|fileprivate|private)\s+)?((?:final\s+)?)(class|struct|actor|enum|extension)\s+" + re.escape(name) + r"\b")
for index, line in enumerate(lines):
    match = pattern.match(line)
    if not match:
        continue
    # The line that opens the body.
    open_at = index
    while "{" not in lines[open_at]:
        open_at += 1
    indent = match.group(1) + "    "
    access = (match.group(3) or "").strip()
    level = access if access in ("public", "package") else ""
    prefix = (level + " " if level else "") + ("static " if static else "")
    doc = f"{indent}/// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another."
    if environment:
        lines[open_at + 1:open_at + 1] = [f"{indent}@Environment(\\.runtime) var runtime", ""]
    else:
        ignored = "@ObservationIgnored " if "@Observable" in line or (index > 0 and "@Observable" in lines[index - 1]) else ""
        lines[open_at + 1:open_at + 1] = [doc, f"{indent}{ignored}{prefix}var runtime = Runtime.live", ""]
    break
else:
    sys.exit(f"{name} not found in {path}")
text = "\n".join(lines)
if environment and "import SunsetShell" not in text and "/SunsetShell/" not in path:
    text = text.replace("import SwiftUI", "import SunsetShell\nimport SwiftUI", 1)
imports = re.findall(r"^(public |package |)import SunsetRuntime$", text, re.M)
if not imports:
    level = "public " if " public " in text or text.startswith("public ") or "\npublic " in text else ("package " if "\npackage " in text else "")
    # After the last import, or at the top.
    found = list(re.finditer(r"^(?:public |package |@\w+ )*import \w+$", text, re.M))
    at = found[-1].end() if found else 0
    text = text[:at] + ("\n" if at else "") + f"{level}import SunsetRuntime" + ("" if at else "\n") + text[at:]
open(path, "w").write(text)
