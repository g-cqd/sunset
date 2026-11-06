---
status: accepted
date: 2026-11-05
---

# 0026 — Replies are a bounded queue; the terminal answers only queries that cannot be abused

## Context

Programs probe the terminal at startup (device attributes, cursor position, mode queries, version, keyboard protocol). A reply goes back into the program's input, so a query is a way for a program to inject input and, for some replies (window title reports), to turn terminal state into commands. White paper §9: anything an untrusted program can ask for needs a policy and a test.

## Decision

- **A queue, not a callback**: the screen appends replies to a bounded buffer (64 KiB) that the host drains (`Terminal.takeReplies()`) and writes to the PTY. Each reply is built on the stack and committed whole or dropped whole; a program that asks faster than the host drains loses the surplus, counted in `droppedReplies`. Tested with 100 000 queries.
- **Answered**: DA1 (`?62;22c`: VT220 level, ANSI colour), DA2 (`>1;10;0c`), DSR 5 and 6 (and DECXCPR `?6n`; row relative to the margin in origin mode), `CSI 18 t` (size in characters), DECRQM for ANSI and DEC modes (0 unknown, 1 set, 2 reset, **4 for DECCOLM: permanently reset**), XTVERSION (`sunset(0.0.1)`), the kitty keyboard flag query.
- **Never answered**: window title and icon-label reports (`CSI 21 t` and kin: the classic injection route), pixel sizes (`14 t`/`16 t`, until the host supplies cell metrics), clipboard reads. DECCOLM (80/132 column switching) is refused, so a program cannot resize the grid.
- **Mode state** is one `Modes` value the host reads (application cursor keys, mouse tracking level and format, focus events, bracketed paste, synchronized output, keypad, reverse video, cursor visibility). Cursor style (DECSCUSR) is recorded. Soft reset (DECSTR) restores modes, pen, margins, saved cursor and cursor style and keeps the text.
- **Kitty keyboard flags**: five bits, a stack of at most 16 per screen (main and alternate separate), push/pop/set (replace, add, remove)/query.

## Evidence (`Tests/SunsetCoreTests/ScreenRepliesTests.swift`, 85 tests in all)

- Tests were written first against stubs and failed (52 issues), then the implementation made them pass. Ten mutants of the new code: nine caught at once; "keyboard stack unbounded" survived (the test pushed and popped the same number), the test was changed to push 20 and pop 16, and the mutant is now caught.
- A query split at every byte is answered like the whole; replies keep the order of the questions; the stream benchmarks are unchanged (50 M instructions per MiB of ASCII, 0 mallocs).

## Not established

- The attribute values and the DECSTR autowrap choice are mine; they have not been compared with kitty, ghostty or wezterm (ADR-0004 oracles, `esctest`). An application keying on exact DA1 features could differ.
- Reply allocation: the queue reserves 256 bytes and grows only when it fills; `takeReplies` copies out and allocates on the host side. Not benchmarked under a query flood.
- OSC queries (colours, clipboard), titles, DECRQSS and XTGETTCAP, hyperlinks and the kitty graphics replies are not done.
