#!/bin/sh
# What terminals that have gone quiet, or are not shown, keep of their surfaces (review of 2026-11-15, 3.2; owner note n14;
# task t267).
#
# A test copy of Sunset (never the person's own) with four terminal tabs. Each one's "shell" prints fast for two seconds
# (frames then come faster than the window server lets go of surfaces, so a third surface is made), then is quiet. Each
# tab is shown in turn, then the first again: one terminal is shown, three are not, all are quiet. The app's memory is
# read one second after the last switch and again five seconds later.
#
#   Scripts/surface-probe/run.sh [path to the Sunset binary]      default: the release app of Scripts/make-app.sh release
#
# Prints, at each of the two times: the IOSurface memory and how many regions it is in, and the app's footprint (vmmap).
set -eu
cd "$(dirname "$0")/../.." || exit 1
binary="${1:-$PWD/.build/app-release/Sunset.app/Contents/MacOS/Sunset}"
axdrive="Tools/axdrive/.build/release/axdrive"
[ -x "$axdrive" ] || { echo "build Tools/axdrive first (swift build -c release)"; exit 2; }
[ -x "$binary" ] || { echo "no binary at $binary"; exit 2; }

work="$(mktemp -d /tmp/surface-probe.XXXXXX)"
cat > "$work/burst.sh" <<'BURST'
#!/bin/sh
printf '\033]0;burst %d\007' "$$"
end=$(($(date +%s) + 2))
while [ "$(date +%s)" -lt "$end" ]; do
    seq 1 400
done
printf 'quiet\n'
exec sleep 3600
BURST
chmod +x "$work/burst.sh"
cat > "$work/session.json" <<'SESSION'
{"favorites": {"contents": [], "favorites": {"nodes": []}}, "version": 2, "windows": [{"contents": [
{"kind": "terminal", "pane": "00000000-0000-0000-0000-000000000001", "state": {"directory": "/tmp"}},
{"kind": "terminal", "pane": "00000000-0000-0000-0000-000000000002", "state": {"directory": "/tmp"}},
{"kind": "terminal", "pane": "00000000-0000-0000-0000-000000000003", "state": {"directory": "/tmp"}},
{"kind": "terminal", "pane": "00000000-0000-0000-0000-000000000004", "state": {"directory": "/tmp"}}],
"workspace": {"items": [
{"focused": "00000000-0000-0000-0000-000000000001", "id": "00000000-0000-0000-0000-000000000065",
 "layout": {"pane": "00000000-0000-0000-0000-000000000001"}},
{"focused": "00000000-0000-0000-0000-000000000002", "id": "00000000-0000-0000-0000-000000000066",
 "layout": {"pane": "00000000-0000-0000-0000-000000000002"}},
{"focused": "00000000-0000-0000-0000-000000000003", "id": "00000000-0000-0000-0000-000000000067",
 "layout": {"pane": "00000000-0000-0000-0000-000000000003"}},
{"focused": "00000000-0000-0000-0000-000000000004", "id": "00000000-0000-0000-0000-000000000068",
 "layout": {"pane": "00000000-0000-0000-0000-000000000004"}}],
"selected": "00000000-0000-0000-0000-000000000065"}}]}
SESSION

# The memory of process $1, as vmmap says it.
memory() {
    vmmap -summary "$1" 2> /dev/null | awk '
        /^Physical footprint:/ { footprint = $3 }
        /^IOSurface / { surfaces = $2; regions = $NF }
        END { printf "IOSurface %s in %s regions; footprint %s\n", surfaces, regions, footprint }
    '
}

launched="$(SHELL="$work/burst.sh" "$axdrive" launch --session "$work/session.json" --binary "$binary")"
pid="${launched%% *}"
sleep 4
for tab in 2 3 4; do
    "$axdrive" menu "$pid" "Window>Tab $tab" > /dev/null
    sleep 4
done
"$axdrive" menu "$pid" "Window>Tab 1" > /dev/null
sleep 1
echo "window: $("$axdrive" windows "$pid" | grep burst | head -1)"
echo "one second after the last switch: $(memory "$pid")"
sleep 5
echo "five seconds later:               $(memory "$pid")"
"$axdrive" menu "$pid" "Sunset>Quit Sunset" > /dev/null 2>&1 || kill "$pid" 2> /dev/null || true
