#!/usr/bin/env bash
# Runs each stream of Scripts/oracle-streams (or the ones named) in other terminals, as processes, and in Sunset, all 80x24, and compares what the
# screens show (white paper section 9, ADR-0004: other terminals are oracles run as processes, never linked).
#
#   Scripts/oracle-compare.sh [stream.sh ...]        ORACLES="kitty ghostty alacritty" (default) chooses which
#
# kitty:   text and styles (`kitten @ get-text`, plain and --ansi; the ANSI dump is replayed through Sunset so that cells and styles can be compared).
# ghostty: text only (Scripts/oracle-ghostty.sh; its screen file carries theme colours, not palette entries).
# alacritty (built with `cargo install alacritty`): replies only (it has no screen dump), for the "queries" streams.
# Prints one verdict per stream and oracle and the differences; exit status 1 if any differs.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
oracles="${ORACLES:-kitty ghostty alacritty}"
kitty=/Applications/kitty.app/Contents/MacOS
(cd "$root" && swift build -c release --product sunset-run 2>&1 | tail -1) || exit 2
run="$root/.build/release/sunset-run"
streams=()
for argument in "$@"; do streams+=("$(cd "$(dirname "$argument")" && pwd)/$(basename "$argument")"); done  # absolute: the terminals start in other directories
[ ${#streams[@]} -gt 0 ] || streams=("$root"/Scripts/oracle-streams/*.sh)
sock="/tmp/sunset-oracle-$$.sock"
out="$(mktemp -d)"
failed=0

accepted="$root/Scripts/oracle-accepted.txt"
# Is this oracle/stream/key difference listed (with its reason) as accepted? key "*" accepts the whole stream.
is_accepted() { awk -F'\t' -v o="$1" -v s="$2" -v k="$3" '!/^#/ && $1 == o && $2 == s && ($3 == k || $3 == "*") { found = 1 } END { exit !found }' "$accepted"; }
# Drops the replies whose differences are accepted, from both files (a reply line starts with its key and a colon).
drop_accepted() { # oracle stream file
    local oracle="$1" stream="$2" file="$3" key
    while IFS= read -r key; do grep -v "^$key:" "$file" > "$file.f"; mv "$file.f" "$file"; done \
        < <(awk -F'\t' -v o="$oracle" -v s="$stream" '!/^#/ && $1 == o && $2 == s && $3 != "*" { print $3 }' "$accepted")
}

# Trailing empty rows are not content.
trim_rows() { awk '{ lines[NR] = $0 } END { n = NR; while (n > 0 && lines[n] == "") n--; for (i = 1; i <= n; i++) print lines[i] }'; }
# Tab characters in a dump stand for blank cells a tab moved over: for tab streams runs of blanks are squeezed on both sides (a weaker check).
squeeze_if_tabs() { case "$1" in *tabs*) tr -s ' \t' '  ' < "$2" > "$2.sq"; mv "$2.sq" "$2" ;; esac; }
verdict() { # name oracle files...
    local name="$1" oracle="$2"
    shift 2
    if "$@"; then echo "  $oracle same     $name"; else echo "  $oracle DIFFERS  $name"; failed=1; fi
}

run_kitty() {
    local stream="$1" name="$2"
    rm -f "$sock"
    "$kitty/kitty" --listen-on "unix:$sock" -o allow_remote_control=yes -o remember_window_size=no \
        -o initial_window_width=80c -o initial_window_height=24c -o confirm_os_window_close=0 \
        /bin/sh -c "/bin/sh '$stream'; touch '$out/$name.kitty.done'; sleep 60" >/dev/null 2>&1 &
    local pid=$!
    for _ in $(seq 1 100); do [ -S "$sock" ] && break; sleep 0.2; done
    # The stream says when it has finished (a loaded machine can be slower than any fixed wait).
    for _ in $(seq 1 150); do [ -f "$out/$name.kitty.done" ] && break; sleep 0.2; done
    # Read the screen until four reads agree (kitty draws asynchronously, and the machine may be busy): no fixed sleep decides.
    local previous="" current="" stable=0
    for _ in $(seq 1 60); do
        current="$("$kitty/kitten" @ --to "unix:$sock" get-text --extent screen 2>/dev/null | sed -e 's/[[:space:]]*$//')"
        if [ -n "$(printf '%s' "$current" | tr -d '[:space:]')" ] && [ "$current" = "$previous" ]; then stable=$((stable + 1)); else stable=0; fi
        [ "$stable" -ge 3 ] && break
        previous="$current"
        sleep 0.4
    done
    printf '%s\n' "$current" | trim_rows > "$out/$name.kitty"
    # The same screen with its styles, as SGR text (the dump ends with a newline that would scroll a full screen on replay).
    "$kitty/kitten" @ --to "unix:$sock" get-text --extent screen --ansi 2>/dev/null | perl -pe 'chomp if eof' > "$out/$name.kitty.ansi"
    "$kitty/kitten" @ --to "unix:$sock" close-window >/dev/null 2>&1
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    squeeze_if_tabs "$name" "$out/$name.kitty"
    "$run" --cols 80 --rows 24 --wait 800 --then-wait 300 --cells -- /bin/cat "$out/$name.kitty.ansi" > "$out/$name.kitty.cells" 2>/dev/null
}

# Streams about replies (names with "queries") write what the program read from the terminal to $ORACLE_OUT and are compared on that file, whatever
# the terminal draws; it works for terminals whose screen cannot be dumped too (alacritty).
wait_for_end() { for _ in $(seq 1 150); do grep -q '^END$' "$1" 2>/dev/null && return 0; sleep 0.2; done; return 1; }
run_file_oracle() { # oracle stream result-file
    local oracle="$1" stream="$2" file="$3" pid
    : > "$file"
    case "$oracle" in
        kitty)
            rm -f "$sock"
            ORACLE_OUT="$file" "$kitty/kitty" --listen-on "unix:$sock" -o allow_remote_control=yes -o remember_window_size=no \
                -o initial_window_width=80c -o initial_window_height=24c -o confirm_os_window_close=0 \
                /bin/sh -c "/bin/sh '$stream'; sleep 60" >/dev/null 2>&1 &
            pid=$!
            wait_for_end "$file"
            "$kitty/kitten" @ --to "unix:$sock" close-window >/dev/null 2>&1
            kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null ;;
        alacritty)
            ORACLE_OUT="$file" "$HOME/.cargo/bin/alacritty" -o window.dimensions.columns=80 -o window.dimensions.lines=24 \
                -e /bin/sh "$stream" >/dev/null 2>&1 &
            pid=$!
            wait_for_end "$file"
            kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null ;;
        ghostty)
            ORACLE_OUT="$file" "$root/Scripts/oracle-ghostty.sh" "$stream" >/dev/null 2>&1 ;;
    esac
    grep -v '^END$' "$file" > "$file.clean"; mv "$file.clean" "$file"
}

for stream in "${streams[@]}"; do
    name="$(basename "$stream" .sh)"
    case "$name" in
        *queries*)
            "$run" --cols 80 --rows 24 --until-exit 60000 --then-wait 100 --plain --env "ORACLE_OUT=$out/$name.sunset.replies" -- /bin/sh "$stream" >/dev/null 2>&1
            grep -v '^END$' "$out/$name.sunset.replies" > "$out/$name.sunset.r"
            for oracle in kitty ghostty alacritty; do
                [[ " ${ORACLES:-kitty ghostty alacritty} " == *" $oracle "* ]] || continue
                [ "$oracle" = alacritty ] && [ ! -x "$HOME/.cargo/bin/alacritty" ] && continue
                run_file_oracle "$oracle" "$stream" "$out/$name.$oracle.replies"
                cp "$out/$name.sunset.r" "$out/$name.$oracle.sunset.r"
                drop_accepted "$oracle" "$name" "$out/$name.$oracle.replies"
                drop_accepted "$oracle" "$name" "$out/$name.$oracle.sunset.r"
                if diff -u "$out/$name.$oracle.replies" "$out/$name.$oracle.sunset.r" > "$out/$name.$oracle.diff"; then
                    echo "  $oracle same     $name (replies)"
                else
                    echo "  $oracle DIFFERS  $name (replies)"
                    sed -e 's/^/      /' "$out/$name.$oracle.diff" | head -60
                    failed=1
                fi
            done
            continue ;;
    esac
    "$run" --cols 80 --rows 24 --wait 1500 --then-wait 300 --plain -- /bin/sh "$stream" > "$out/$name.sunset" 2>/dev/null
    "$run" --cols 80 --rows 24 --wait 1500 --then-wait 300 --cells -- /bin/sh "$stream" > "$out/$name.sunset.cells" 2>/dev/null
    squeeze_if_tabs "$name" "$out/$name.sunset"
    if [[ " $oracles " == *" kitty "* ]] && [ -x "$kitty/kitty" ]; then
        run_kitty "$stream" "$name"
        verdict "$name" kitty diff -u "$out/$name.kitty" "$out/$name.sunset" > "$out/$name.kitty.verdict"
        cat "$out/$name.kitty.verdict"
        diff -u "$out/$name.kitty" "$out/$name.sunset" | sed -e 's/^/      /' | head -30
        # Styles, except for tab streams (tab characters in the dump) and the scroll-with-colour stream (the dump drops rows that only carry a background).
        case "$name" in
            *tabs* | *bce-scroll*) ;;
            *)
                if ! diff -u "$out/$name.kitty.cells" "$out/$name.sunset.cells" > "$out/$name.cells.diff"; then
                    echo "  kitty STYLES DIFFER  $name"
                    sed -e 's/^/      /' "$out/$name.cells.diff" | head -30
                    failed=1
                fi ;;
        esac
    fi
    if [[ " $oracles " == *" ghostty "* ]]; then
        "$root/Scripts/oracle-ghostty.sh" "$stream" 2> "$out/$name.ghostty.err" | trim_rows > "$out/$name.ghostty.all"
        # Ghostty's screen file holds the history as well as the screen: keep the last as many lines as Sunset's screen has.
        tail -n "$(wc -l < "$out/$name.sunset")" "$out/$name.ghostty.all" > "$out/$name.ghostty"
        squeeze_if_tabs "$name" "$out/$name.ghostty"
        if is_accepted ghostty "$name" "*"; then
            echo "  ghostty accepted $name ($(awk -F'\t' -v s="$name" '$1 == "ghostty" && $2 == s && $3 == "*" { print $4 }' "$accepted"))"
        else
            verdict "$name" ghostty diff -u "$out/$name.ghostty" "$out/$name.sunset" > "$out/$name.ghostty.verdict"
            cat "$out/$name.ghostty.verdict"
            diff -u "$out/$name.ghostty" "$out/$name.sunset" | sed -e 's/^/      /' | head -30
        fi
        [ -s "$out/$name.ghostty.err" ] && sed -e 's/^/      ! /' "$out/$name.ghostty.err"
    fi
done
rm -f "$sock"
echo "(files: $out)"
exit $failed
