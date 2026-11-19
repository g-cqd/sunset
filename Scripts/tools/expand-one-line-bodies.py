#!/usr/bin/env python3
"""Spans the one-line bodies of Swift declarations over lines of their own (ADR-0087, the owner's note n55).

    var isEmpty: Bool { items.isEmpty }      ->   var isEmpty: Bool {
                                                       items.isEmpty
                                                   }

A body is that of a `func`, `init`, `subscript`, `deinit`, a computed `var`, or an accessor (`get`, `set`, `didSet`,
`willSet`). Protocol requirements (`{ get }`, `{ get set }`) are not bodies. Run with paths; `--check` only counts.
"""
import re
import sys

MODIFIERS = r"(?:(?:@\w+(?:\([^()]*\))?|public|package|private|fileprivate|internal|open|static|class|final|override|" \
            r"nonisolated|mutating|nonmutating|lazy|weak|unowned|convenience|required|dynamic|indirect|consuming|" \
            r"borrowing|private\(set\)|package\(set\)|internal\(set\)|fileprivate\(set\)|public\(set\))\s+)*"
HEAD = re.compile(r"^(\s*)(" + MODIFIERS + r"(?:func|init[?!]?|subscript|deinit|var|get|set|didSet|willSet|_read|_modify)\b(?!\s*:))")
REQUIREMENTS = {"get", "set", "get set", "set get", "get async", "get throws", "get async throws", "nonmutating set",
                "get nonmutating set", "mutating get"}


def split_comment(line):
    """The code and a trailing `//` comment, strings respected."""
    in_string = False
    i = 0
    while i < len(line):
        c = line[i]
        if c == "\\" and in_string:
            i += 2
            continue
        if c == '"':
            in_string = not in_string
        elif not in_string and line.startswith("//", i):
            return line[:i].rstrip(), line[i:]
        i += 1
    return line.rstrip(), ""


def body_span(code):
    """(start, end) of the block opened by the first `{` at depth 0, when it closes at the line's end; else None."""
    depth = 0
    paren = 0
    in_string = False
    start = None
    i = 0
    while i < len(code):
        c = code[i]
        if c == "\\" and in_string:
            i += 2
            continue
        if c == '"':
            in_string = not in_string
        elif not in_string:
            if c in "([":
                paren += 1
            elif c in ")]":
                paren -= 1
            elif c == "{":
                if depth == 0 and paren == 0 and start is None:
                    start = i
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0 and start is not None:
                    return (start, i) if i == len(code) - 1 else None
        i += 1
    return None


def one_line_body(line):
    """(indent, head, body, comment) when `line` is a declaration with its body on it; else None."""
    match = HEAD.match(line)
    if not match:
        return None
    code, comment = split_comment(line)
    span = body_span(code)
    if not span:
        return None
    head = code[:span[0]].rstrip()
    body = code[span[0] + 1:span[1]].strip()
    if not body or body in REQUIREMENTS:
        return None
    keyword = re.sub(r"^" + MODIFIERS, "", match.group(2).strip())
    if keyword == "var":
        # A stored property's observers are a body too; its closure (`var x = { … }`) or initial value is not.
        if re.match(r"^(didSet|willSet)\b", body):
            return match.group(1), head, body, comment
        if "=" in re.sub(r"\([^()]*\)", "", head):
            return None
        if ":" not in head:
            return None
    return match.group(1), head, body, comment


def expand(text):
    out = []
    changed = 0
    for line in text.split("\n"):
        found = one_line_body(line)
        if not found:
            out.append(line)
            continue
        indent, head, body, comment = found
        out.append(f"{indent}{head.strip()} {{" + (f"  {comment}" if comment else ""))
        out.append(f"{indent}    {body}")
        out.append(f"{indent}}}")
        changed += 1
    return "\n".join(out), changed


def main():
    check = "--check" in sys.argv
    paths = [p for p in sys.argv[1:] if p != "--check"]
    total = 0
    for path in paths:
        text = open(path).read()
        new, changed = expand(text)
        # Again, for a body that held another one-line body (an accessor in a property).
        while changed and not check:
            total += changed
            text = new
            new, changed = expand(text)
            if not changed:
                break
        if check:
            total += changed
        elif text != open(path).read():
            open(path, "w").write(text)
    print(total)


if __name__ == "__main__":
    main()
