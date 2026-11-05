---
status: not-started
blocked-by: 0003
date: 2026-11-05
---

# 0004 — PTY host and the headless orchestration API

`openpty` + `posix_spawn(POSIX_SPAWN_SETSID)` with `dup2` file actions: probed, the child has a controlling tty and is the foreground group (diary 2026-11-05-01). **Not probed:** job control (Ctrl-Z, fg), SIGWINCH on resize, login/utmp, Linux. API: spawn, keys, resize, screen snapshot, replies, recording and replay. First consumer: ask's interface probes (replace pyte) and TerminalUI's harness.
