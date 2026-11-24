#!/bin/sh
# Mutation testing (litmus, through swift-ci's `mutation` command of .ci/action.json), started in the background: this returns at once.
# Never run by the loop or a gate (ADR-0126). The log is .build/mutation/<time>.log; .build/mutation/running holds the pid while it goes.
#
#   Scripts/mutate-async.sh          start a run
#   Scripts/mutate-async.sh status   say whether one is going, and where the last log is
set -eu
cd "$(dirname "$0")/.."
dir=.build/mutation
mkdir -p "$dir"
running="$dir/running"
alive() { [ -f "$running" ] && kill -0 "$(cat "$running")" 2> /dev/null; }
if [ "${1:-}" = status ]; then
    if alive; then echo "running (pid $(cat "$running")); log: $(ls -t "$dir"/*.log | head -n 1)"; else
        echo "not running; last log: $(ls -t "$dir"/*.log 2> /dev/null | head -n 1)"
    fi
    exit 0
fi
if alive; then echo "a run is going already (pid $(cat "$running")); see: $0 status" >&2; exit 1; fi
log="$dir/$(date +%Y%m%d-%H%M%S).log"
nohup sh -c 'echo $$ > "$1"; .ci/swift-ci run mutation > "$2" 2>&1; rm -f "$1"' sh "$running" "$log" > /dev/null 2>&1 &
echo "started in the background; log: $log"
