#!/bin/sh
# Instructions per MiB of each stream through a headless terminal (120x40), release build. bench/instructions/run.sh [stream ...]
set -eu
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"
swift build -c release >/dev/null 2>&1 || { swift build -c release 2>&1 | grep error; exit 1; }
tool=$(swift build -c release --show-bin-path)/instructions
counter=$(mktemp -d)/count
clang -O2 "$here/count.c" -o "$counter"
rounds=100
[ $# -gt 0 ] || set -- scroll newlines returns letters lines
for name in "$@"; do
    total=$("$counter" "$tool" "$name" "$rounds")
    printf '%-10s %8.1f M instructions per MiB\n' "$name" "$(echo "$total / $rounds" | bc -l)"
done
