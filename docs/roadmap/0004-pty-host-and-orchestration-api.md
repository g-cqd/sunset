---
status: mostly-done (as of 2026-11-11: PTYProcess, the output pump, TerminalSession, HeadlessSession, sunset-run built. Not built: recording and replay, the API for other processes, Linux.)
blocked-by:
date: 2026-11-05
---

# 0004 — PTY host and the headless orchestration API

`openpty` + `posix_spawn(POSIX_SPAWN_SETSID)` with `dup2` file actions: probed, the child has a controlling tty and is the foreground group (diary 2026-11-05-01). **Not probed:** job control (Ctrl-Z, fg), SIGWINCH on resize, login/utmp, Linux. API: spawn, keys, resize, screen snapshot, replies, recording and replay. First consumer: ask's interface probes (replace pyte) and TerminalUI's harness.

## Progress (2026-11-05): ADR-0030

Done: `PTYProcess`, `HeadlessSession`, `sunset-run`, 10 tests (spawn, session and controlling terminal, size and resize, replies, keys, exit status, environment, history, Unicode, missing program). Not done: job control, Linux, recording and replay, the API for other processes (remote control, ADR-0022), thread safety, login records.
