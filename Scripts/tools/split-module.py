#!/usr/bin/env python3
"""After files move from a module into a new one (a model apart from its views), makes what was internal
across them visible again, then builds until the package builds or nothing more can be done by rule.

    Scripts/tools/split-module.py Sources/SunsetTerminalModel

1. Every declaration of the moved module without an access level, at file level or as a member of a type or an
   extension (not inside a function, a protocol or a closure), becomes `package`.
2. Then, build by build:
   - a declaration the build says is inaccessible, or cannot find, becomes `package` (members, nested types);
   - a struct whose memberwise initializer is used across the boundary gets it written out;
   - a file whose package API names an imported type imports it at package level; one that no longer does, plainly;
   - a missing import of a defining module is added.
It prints what is left when no rule applies: those are the decisions (a file that belongs on the other side)."""
import glob
import re
import subprocess
import sys

MODULE = sys.argv[1].rstrip('/')
FILES = f'{MODULE}/*.swift'
ACCESS = re.compile(r'\b(public|package|internal|private|fileprivate|open)\b')
DECL = re.compile(
    r'^(\s*)((?:@[\w.]+(?:\([^)]*\))?\s+)*)'
    r'((?:(?:static|class|final|override|mutating|nonmutating|nonisolated|lazy|weak|unowned|convenience|required|'
    r'indirect|dynamic|@ObservationIgnored)\s+)*)'
    r'(let|var|func|init[?!]?|subscript|struct|class|enum|actor|protocol|typealias)\b')
TYPE_OPEN = re.compile(
    r'^\s*(?:@[\w.]+(?:\([^)]*\))?\s+)*(?:(?:public|package|internal|private|fileprivate|final|indirect)\s+)*'
    r'(?:struct|class|enum|actor|protocol|extension)\b')
IMPORTABLE = ('SwiftUI|AppKit|SunsetPane|Foundation|CoreGraphics|SunsetRuntime|SunsetMetrics|SunsetStorage|'
              'SunsetShellModel|Network|WebKit|Observation|SunsetCore|SunsetHost|SunsetRender|SunsetRenderMac|'
              'SunsetRenderMetal|SunsetConfig|IOSurface')


def code_of(line):
    return re.sub(r'"(?:\\.|[^"\\])*"', '""', line).split('//')[0]


def make_package(path):
    """Step 1 for one file; how many declarations changed."""
    lines = open(path).read().split('\n')
    stack, protocols, changed = [], [], 0
    for index, line in enumerate(lines):
        code = code_of(line)
        member_level = all(stack)
        in_protocol = bool(protocols) and protocols[-1]
        m = DECL.match(code)
        if m and member_level and not in_protocol and not ACCESS.search(code.split('{')[0].split('=')[0]):
            lines[index] = line[:m.start(2)] + m.group(2) + 'package ' + line[m.start(3):]
            changed += 1
        is_type = bool(TYPE_OPEN.match(code))
        is_protocol = bool(re.match(r'^\s*(?:@\w+\s+)*(?:(?:public|package|internal)\s+)?protocol\b', code))
        for c in code:
            if c == '{':
                stack.append(is_type)
                protocols.append(is_protocol)
                is_type = is_protocol = False
            elif c == '}' and stack:
                stack.pop()
                protocols.pop()
    open(path, 'w').write('\n'.join(lines))
    return changed


def write_memberwise(name):
    for path in glob.glob(FILES):
        s = open(path).read()
        m = re.search(r'^(\s*)package struct ' + name + r'\b[^{]*\{\n', s, re.M)
        if not m:
            continue
        indent = m.group(1) + '    '
        members = re.findall(
            r'^' + indent + r'(?:package |public )?(?:@\w+ )*(let|var) (\w+): ([^={\n]+?)(?: = ([^\n]+))?$',
            s[m.end():], re.M)
        members = [x for x in members if 'static' not in x]
        params = [f'{p}: {t.strip()}' + (f' = {d}' if d else '') for k, p, t, d in members if not (k == 'let' and d)]
        if not params:
            init = f'{indent}package init() {{}}\n\n'
            s = s[:m.end()] + init + s[m.end():]
        else:
            body = '\n'.join(f'{indent}    self.{p.split(":")[0]} = {p.split(":")[0]}' for p in params)
            init = f'\n{indent}package init(\n' + ',\n'.join(f'{indent}    {p}' for p in params) + f'\n{indent}) {{\n{body}\n{indent}}}\n'
            last = members[-1][1]
            at = s.find('\n', s.find(f' {last}: ', m.end())) + 1
            s = s[:at] + init + s[at:]
        open(path, 'w').write(s)
        return True
    return False


def promote(name):
    for path in glob.glob(FILES):
        lines = open(path).read().split('\n')
        for i, line in enumerate(lines):
            code = code_of(line)
            if (re.search(r'\b(?:let|var|func|struct|class|enum|typealias|case)\s+' + re.escape(name) + r'\b', code)
                    and not ACCESS.search(code)):
                m = DECL.match(code)
                if m:
                    lines[i] = line[:m.start(2)] + m.group(2) + 'package ' + line[m.start(3):]
                    open(path, 'w').write('\n'.join(lines))
                    return True
    return False


def add_import(path, module, level=''):
    s = open(path).read()
    if re.search(rf'^(?:package |public |internal )?import {module}$', s, re.M):
        return False
    found = list(re.finditer(r'^(?:package |public |@\w+ )*import \w+$', s, re.M))
    at = found[0].start() if found else 0
    open(path, 'w').write(s[:at] + f'{level}import {module}\n' + s[at:])
    return True


changed = sum(make_package(p) for p in glob.glob(FILES))
print(f'{changed} declarations made package')
for round_ in range(80):
    result = subprocess.run(['swift', 'build', '--build-tests'], capture_output=True, text=True)
    log = re.sub(r'\x1b\[[0-9;]*m', '', result.stdout + result.stderr)
    if result.returncode == 0:
        print('builds after', round_, 'rounds')
        break
    fixed = 0
    for name in sorted(set(n.split('.')[-1] for n in re.findall(
            r"error: '([\w.]+)' initializer is inaccessible due to 'internal' protection level", log))):
        fixed += write_memberwise(name)
    names = set(re.findall(r"error: '(\w+)' is inaccessible due to 'internal' protection level", log))
    names |= set(re.findall(r"error: cannot find (?:type )?'(\w+)' in scope", log))
    for name in sorted(names):
        fixed += promote(name)
    for path in set(re.findall(r"(/\S+\.swift):\d+:\d+: error: [^\n]*? cannot be declared (?:package|public) because its", log)):
        s = open(path).read()
        new = re.sub(rf'^(?:internal )?import ({IMPORTABLE})$', r'package import \1', s, flags=re.M)
        if new != s:
            open(path, 'w').write(new)
            fixed += 1
    for path, module in set(re.findall(r"(/\S+\.swift):\d+:\d+: error: (?:package|public) import of '(\w+)' was not used", log)):
        s = open(path).read()
        new = re.sub(rf'^(?:package|public) import {module}$', f'import {module}', s, flags=re.M)
        if new != s:
            open(path, 'w').write(new)
            fixed += 1
    for path, module in set(re.findall(r"(/\S+\.swift):\d+:\d+: error: [^\n]*?missing import of defining module '(\w+)'", log)):
        fixed += add_import(path, module)
    if not fixed:
        print('left after', round_, 'rounds:')
        print('\n'.join(sorted(set(re.findall(r'/(?:Sources|Tests)/(\S+\.swift:\d+:\d+: error: [^\n]*)', log)))[:20]))
        break
