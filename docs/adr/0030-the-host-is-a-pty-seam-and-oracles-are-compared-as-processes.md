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
