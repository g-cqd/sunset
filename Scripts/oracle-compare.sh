#!/usr/bin/env bash
# Runs each stream in Scripts/oracle-streams (or the ones named) in kitty, as a process, and in Sunset headless, both 80x24, and compares the text of
# the two screens (white paper section 9, ADR-0004: other terminals are oracles run as processes, never linked). Kitty's screen is read with
# `kitten @ get-text`. Prints the differences; exit status 1 if any stream differs.
#
#   Scripts/oracle-compare.sh [stream.sh ...]
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kitty=/Applications/kitty.app/Contents/MacOS
[ -x "$kitty/kitty" ] || { echo "kitty is not installed at $kitty" >&2; exit 2; }
(cd "$root" && swift build -c release --product sunset-run 2>&1 | tail -1) || exit 2
run="$root/.build/release/sunset-run"
streams=("$@")
[ ${#streams[@]} -gt 0 ] || streams=("$root"/Scripts/oracle-streams/*.sh)
sock="/tmp/sunset-oracle-$$.sock"
out="$(mktemp -d)"
failed=0
for stream in "${streams[@]}"; do
    name="$(basename "$stream" .sh)"
    rm -f "$sock"
    "$kitty/kitty" --listen-on "unix:$sock" -o allow_remote_control=yes -o remember_window_size=no \
        -o initial_window_width=80c -o initial_window_height=24c -o confirm_os_window_close=0 \
        /bin/sh -c "/bin/sh '$stream'; sleep 60" >/dev/null 2>&1 &
    pid=$!
    for _ in $(seq 1 100); do [ -S "$sock" ] && break; sleep 0.2; done
    # Read the screen until two reads agree (kitty draws asynchronously, and the machine may be busy): no fixed sleep decides.
    previous=""
    for _ in $(seq 1 50); do
        current="$("$kitty/kitten" @ --to "unix:$sock" get-text --extent screen 2>/dev/null | sed -e 's/[[:space:]]*$//')"
        if [ -n "$(printf '%s' "$current" | tr -d '[:space:]')" ] && [ "$current" = "$previous" ]; then break; fi
        previous="$current"
        sleep 0.4
    done
    printf '%s\n' "$current" > "$out/$name.kitty.raw"
    "$kitty/kitten" @ --to "unix:$sock" close-window >/dev/null 2>&1
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    # Trailing empty rows are not content.
    awk '{ lines[NR] = $0 } END { n = NR; while (n > 0 && lines[n] == "") n--; for (i = 1; i <= n; i++) print lines[i] }' "$out/$name.kitty.raw" > "$out/$name.kitty"
    "$run" --cols 80 --rows 24 --wait 1500 --then-wait 300 --plain -- /bin/sh "$stream" > "$out/$name.sunset" 2>/dev/null
    # Kitty's dump keeps the tab characters a tab moved over; we have blank cells. For the streams about tabs the runs of blanks are squeezed on both
    # sides, so only the characters and their order are compared (a weaker check, said so here).
    case "$name" in
        *tabs*)
            tr -s ' \t' '  ' < "$out/$name.kitty" > "$out/$name.kitty.sq"; mv "$out/$name.kitty.sq" "$out/$name.kitty"
            tr -s ' \t' '  ' < "$out/$name.sunset" > "$out/$name.sunset.sq"; mv "$out/$name.sunset.sq" "$out/$name.sunset" ;;
    esac
    if diff -u "$out/$name.kitty" "$out/$name.sunset" > "$out/$name.diff"; then
        echo "same     $name"
    else
        echo "DIFFERS  $name"
        sed -e 's/^/    /' "$out/$name.diff" | head -40
        failed=1
    fi
done
rm -f "$sock"
echo "(files: $out)"
exit $failed
