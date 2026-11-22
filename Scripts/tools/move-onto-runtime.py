#!/usr/bin/env python3
"""Moves raw tasks, sleeps and reads of the time onto `Runtime`. Mechanical; the build then says where a type
has no `runtime` yet, and each is given one there. Run with paths."""
import re
import sys

RULES = [
    (re.compile(r"(?<![\w.])Task\.detached\("), "runtime.detached("),
    (re.compile(r"(?<![\w.])Task\(priority:"), "runtime.task(priority:"),
    (re.compile(r"(?<![\w.])Task \{"), "runtime.task {"),
    (re.compile(r"try\? await Task\.sleep\(for: "), "await runtime.sleep(for: "),
    (re.compile(r"try\? await Task\.sleep\(\s*$"), "await runtime.sleep("),
    (re.compile(r"try\? await Task\.sleep\(until: ([^,]+), clock: \.continuous\)"), r"await runtime.sleep(until: \1)"),
    (re.compile(r"(?<![\w.])ContinuousClock\.now"), "runtime.uptime()"),
    (re.compile(r"(?<![\w.])ContinuousClock\(\)\.now"), "runtime.uptime()"),
]
# A task that holds `self` weakly takes the runtime by value, to sleep on it without `self`.
WEAK_CAPTURE = re.compile(r"(runtime\.(?:task|detached)\b[^{]*\{\s*(?:@\w+\s*)?\[)([^\]]*\bweak self\b[^\]]*)(\])")
DEFAULT_DATE = re.compile(r"(:\s*Date\s*=\s*)Date\(\)")
DATE = re.compile(r"(?<![\w.])Date\(\)")

for path in sys.argv[1:]:
    text = open(path).read()
    new = []
    for line in text.split("\n"):
        if line.strip().startswith("//"):
            new.append(line)
            continue
        for pattern, replacement in RULES:
            line = pattern.sub(replacement, line)
        line = WEAK_CAPTURE.sub(lambda m: m.group(1) + m.group(2) + ("" if "runtime" in m.group(2) else ", runtime") + m.group(3), line)
        line = DEFAULT_DATE.sub(r"\1Runtime.live.now()", line)
        line = DATE.sub("runtime.now()", line)
        new.append(line)
    out = "\n".join(new)
    if out != text:
        open(path, "w").write(out)
