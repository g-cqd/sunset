#!/bin/bash
# Reproducibility probe: runs a benchmark command N times per condition and prints median, min, max and coefficient of variation per metric.
# Conditions: ambient (whatever else runs) and hog (a controlled heavy-contention profile from bench/hog.c, started before the runs and held until they end).
# Usage: bench/repro.sh <runs> <hog-threads> <hog-mix> <hog-qos> -- <command that prints "TAG name=value ...">
set -euo pipefail
RUNS="$1"; HT="$2"; MIX="$3"; QOS="$4"; shift 5
HOG="${HOG:-/tmp/hog}"
stats() { python3 "$(dirname "$0")/stats.py"; }
run_all() { for _ in $(seq 1 "$RUNS"); do "$@"; done; }
if [ -z "${SKIP_AMBIENT:-}" ]; then echo "== ambient   (load: $(uptime | sed 's/.*load averages: //'))"; run_all "$@" | stats; fi
echo "== hog ($HT threads, mix=$MIX, qos=$QOS)"
"$HOG" "$HT" $((RUNS * 40 + 30)) "$QOS" "$MIX" >/dev/null & HP=$!
sleep 3; echo "   (load: $(uptime | sed 's/.*load averages: //'))"; run_all "$@" | stats
kill $HP 2>/dev/null || true; wait $HP 2>/dev/null || true
