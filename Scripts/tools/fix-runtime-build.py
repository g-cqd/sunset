#!/usr/bin/env python3
"""After `move-onto-runtime.py` (ADR-0087): reads a build log on stdin and fixes what is mechanical. A file that uses the
runtime imports SunsetRuntime; a `runtime` capture the closure never uses goes. Prints what it changed."""
import re
import sys

log = sys.stdin.read()
changed = set()
for path, line in set(re.findall(r"(/[^\s:]+\.swift):(\d+):\d+: (?:\x1b\[[0-9;]*m)*error: (?:\x1b\[[0-9;]*m)*capture 'runtime' was never used", log)):
    lines = open(path).read().split("\n")
    index = int(line) - 1
    lines[index] = lines[index].replace(", runtime]", "]").replace("[runtime, ", "[").replace(" [runtime] in", " in")
    open(path, "w").write("\n".join(lines))
    changed.add(path)
for path in set(re.findall(r"(/[^\s:]+\.swift):\d+:\d+: (?:\x1b\[[0-9;]*m)*error: (?:\x1b\[[0-9;]*m)*.*due to missing import of defining module 'SunsetRuntime'", log)):
    text = open(path).read()
    if "import SunsetRuntime" in text:
        continue
    found = list(re.finditer(r"^(?:public |package |@\w+ )*import \w+$", text, re.M))
    at = found[-1].end() if found else 0
    text = text[:at] + ("\n" if at else "") + "import SunsetRuntime" + ("" if at else "\n") + text[at:]
    open(path, "w").write(text)
    changed.add(path)
# A default argument (`= Runtime.live.now()`) needs the import at its declaration's level.
for path, line in set(re.findall(r"(/[^\s:]+\.swift):(\d+):\d+: (?:\x1b\[[0-9;]*m)*error: (?:\x1b\[[0-9;]*m)*cannot find 'Runtime' in scope", log)):
    text = open(path).read()
    if re.search(r"^(public |package |)import SunsetRuntime$", text, re.M):
        continue
    lines = text.split("\n")
    index = int(line) - 1
    while index > 0 and not re.search(r"\b(func|init|subscript)\b", lines[index]):
        index -= 1
    level = "public " if "public " in lines[index] else ""
    found = list(re.finditer(r"^(?:public |package |@\w+ )*import \w+$", text, re.M))
    at = found[-1].end() if found else 0
    text = text[:at] + ("\n" if at else "") + f"{level}import SunsetRuntime" + ("" if at else "\n") + text[at:]
    open(path, "w").write(text)
    changed.add(path)
print("\n".join(sorted(changed)))
