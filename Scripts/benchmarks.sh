#!/bin/sh
# Sunset's benchmarks on ordo-one/benchmark (ADR-0018). Release only. Optional standard contention profile (ADR-0017).
#
#   Scripts/benchmarks.sh [--contend] [args for `swift package benchmark`]     run every suite and print the results
#   Scripts/benchmarks.sh [--contend] baseline <name>                          record a baseline (kept in Benchmarks/.benchmarkBaselines)
#   Scripts/benchmarks.sh [--contend] compare <name>                           run and compare with a baseline; non-zero on a threshold breach
#
# --contend holds one CPU-spinning thread per logical CPU at the benchmark's QoS (bench/hog.c) for the length of the run and prints the
# ambient load average first. Wall-clock numbers from different sessions are not comparable; compare baselines taken in one sitting (ADR-0017).
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
contend=0
if [ "${1:-}" = "--contend" ]; then contend=1; shift; fi
hogpid=""
cleanup() { [ -n "$hogpid" ] && kill "$hogpid" 2>/dev/null || true; }
trap cleanup EXIT INT TERM HUP
printf 'load average before: %s\n' "$(uptime | sed 's/.*load averages*: //')"
if [ "$contend" = 1 ]; then
    hog=$(mktemp -d)/hog
    clang -O2 "$root/bench/hog.c" -o "$hog"
    "$hog" "$(sysctl -n hw.logicalcpu)" 3600 interactive spin >/dev/null &
    hogpid=$!
    printf 'contention: %s spinning threads at user-interactive QoS\n' "$(sysctl -n hw.logicalcpu)"
    sleep 2
fi
cd "$root/Benchmarks"
case "${1:-}" in
    baseline) shift; swift package --allow-writing-to-package-directory benchmark baseline update "$@" --no-progress ;;
    compare)  shift; swift package benchmark baseline compare "$@" --no-progress ;;
    *)        swift package benchmark --no-progress "$@" ;;
esac
