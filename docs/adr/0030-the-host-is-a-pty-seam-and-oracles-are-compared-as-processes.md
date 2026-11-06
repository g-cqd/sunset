---
status: accepted
date: 2026-11-05
---

# 0030 — The host is a PTY seam beside the core; kitty is compared as a process

## Decision

- **`SunsetHost`** is the only target that imports the platform. `PTYProcess` opens a pseudo-terminal (`openpty`), starts the program with `posix_spawnp` in a new session (`POSIX_SPAWN_SETSID`) and opens the slave by name in the child, which makes it the controlling terminal; the window size is set at the start and by `resize` (the kernel signals the foreground group). The master is close-on-exec, the child gets `SIGHUP` and is reaped when the object goes away. `HeadlessSession` runs a program with a `Terminal`: output goes through the parser into the screen, replies go back to the program, keys and resizes go in. `wait(until:)` pumps until a condition holds or a deadline passes (no fixed sleeps).
- **`sunset-run`** (executable) runs a program in a headless session and prints the screen (`--plain` gives the text as logical lines, for comparison).
- **`Scripts/oracle-compare.sh`** runs each stream of `Scripts/oracle-streams` in kitty (as a process, window 80x24, text read with `kitten @ get-text` once two reads agree) and in Sunset, and diffs the text (ADR-0004: oracles run as processes, never linked). The streams: wrapping, tabs, wide characters, combining marks and emoji clusters, scroll regions, insert/delete, erase, origin mode, DECALN with line drawing, alternate screen, REP with save/restore, 100 lines of history, autowrap off, back-colour erase, IND/NEL/LNM.

## Evidence

- 10 host tests (output reaches the screen; the child is in a session with a controlling terminal; size at start and after resize, seen by `stty size`; replies reach the program, tested with a CPR-style DSR answered into `dd`; keys; exit status; environment; 3000 lines into history; non-ASCII and combining marks; a missing program is an error) pass, 160 tests in all.
- **All 15 streams give the same text in kitty 0.49.2 and in Sunset**, after two harness differences were accounted for (kitty's dump joins wrapped rows, which `--plain` now does; kitty's dump keeps the tab characters a tab moved over, so for the tab stream runs of blanks are squeezed on both sides, a weaker check, said so in the script). A first run showed one false difference caused by reading kitty's screen before it had drawn; fixed by reading until two reads agree.
- Real programs: `vim -u NONE` shows typed text and the insert-mode line, `less` of a short file draws exactly what kitty draws from the same bytes (the file starts at the bottom after the alternate-screen switch, in both).

## Not established

- Only text is compared: not colours or attributes, not the cursor position (kitty's `--add-cursor` gave a position I could not reconcile with the stream and I did not pursue it), not images, not behaviour under resize. Only kitty has been used as an oracle; ghostty and wezterm are installed and unused; no `esctest`/`vttest` yet.
- 15 streams are a start, not coverage; replies (DA, DECRQM and the rest) are not compared with kitty's answers.
- The PTY seam is macOS only (no Linux), job control (Ctrl-Z, fg), login records and the behaviour of programs that change the window size themselves are untested; `HeadlessSession` is not thread-safe.

## Addendum: styles (same day)

Styles are compared too: kitty's `get-text --ansi` dump is replayed through Sunset (`sunset-run --cells`) and its cells and styles (colours, attributes, underline style) are compared with those of the stream run directly in Sunset. 17 streams now (two new ones: every SGR attribute and colour form including colon forms and true colour; back-colour erase with scrolling), **all equal**. Limits of the method, found on the way and handled in the script: the dump ends with a newline that scrolls a full screen on replay (stripped); it drops blank cells at the end of a row even when they carry a background and drops rows that only carry one, so back-colour erase on empty cells and one scroll stream are compared on text only; it does not carry overline (SGR 53), so the stream does not use it (unit tests cover it); tab streams are compared with blanks squeezed. Cursor position, replies, resize and images are still not compared with kitty.

## Addendum: ghostty and alacritty as oracles (same day, owner suggestion)

- **Ghostty** (1.4.0) is driven by AppleScript (`Scripts/oracle-ghostty.sh`): a window runs a small loop that waits for the harness, runs the stream and waits to be told to end; the window is sized to 80x24 cells by trial against `stty size` (cached); the text of the screen comes from Ghostty's own `write_screen_file:copy` action (its screen file includes the history, so the last as many lines as Sunset's screen has are compared; the file carries theme colours, so styles are not compared) and the system clipboard it uses is saved and put back. A Ghostty window cannot be closed while a program runs in it without a prompt: the loop ends first, then the terminal is closed, and only if it does not end is the one process Ghostty reports on that tty signalled. **A first version ran `kill` with the pid 0 Ghostty reports when it does not know, which signals the whole process group: it killed the harness's own shell; the script now signals only a pid greater than 1 that is on that terminal's tty.**
- **Alacritty** 0.17.0 is built from source (`cargo install alacritty`; the Homebrew cask is disabled by Homebrew's Gatekeeper rule, so it was not installed that way). It has no screen dump, so it takes part in the **reply streams**: a stream named `*queries*` writes what the program read from the terminal to `$ORACLE_OUT` and is compared on that file for every terminal, whatever it draws (`Scripts/oracle-table.py DIR` prints the replies side by side).
- **Findings, all four terminals:** text equal on all 17 streams in kitty and in ghostty except one (tabs: after text in the last column, back-tab keeps the pending wrap in ghostty and clears it in Sunset and kitty; undecided). Replies, 27 queries: Sunset equals the majority on all but a handful, each listed with its reason in `Scripts/oracle-accepted.txt`: kitty omits the page number of DECXCPR and reports the wrapped position after a write in the last column and does not know mode 12; Sunset's report of DECCOLM as permanently reset is deliberate (it never resizes on request); alacritty does not answer DECXCPR and does not know modes 3 and 5. The comparison found two real inconsistencies in Sunset, both fixed: DECXCPR lacked the page number, and mode 12 (cursor blink) was a separate flag from DECSCUSR's blink state (now one state, reported as set by default like ghostty).
- Harness hardening found on the way: relative stream paths (alacritty starts in the home directory), kitty's screen read before the stream had finished (the stream now touches a done file; four equal reads), `sunset-run --until-exit` for long streams.
- Not done: wezterm; the accepted differences are accepted, not verified against xterm; screen text for alacritty; cursor position, resize and images against any oracle.
