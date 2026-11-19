---
status: in-progress
blocked-by: the owner's choice on generic hiding (ADR-0101)
date: 2026-11-19
---

# 0101 — Blocking: other lists, and what blocking costs (note n58, task t109)

| Step | What | Status |
|---|---|---|
| A | Measured: launch and refresh cost, a page's cost per list, where it is, six other lists (diary 2026-11-19-08) | done |
| B | Compiled once, looked up after; converting off the main actor; kept lists before any fetch; unused parts removed | done (launch ~770 ms → ~4 ms of the main thread) |
| C | Hosts files, `#` comments, sites that must be host names, lists split past 150,000 rules | done (all six lists compile) |
| D | Settings: add a list by its https address, remove one (at most 16) | done, not seen on screen |
| E | Generic hiding: keep, leave out, or apply late from Sunset's world | the owner's choice |
| F | Real sites with the network, release, percentiles; against Safari with a content blocker | not-started |

Not done: E, F; D unseen.
