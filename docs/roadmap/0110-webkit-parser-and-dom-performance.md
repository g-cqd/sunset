---
status: in-progress
blocked-by: nothing
date: 2026-11-21
---

# 0110 — WebKit's parser and DOM: places orders of magnitude slow (the owner, 2026-11-21)

The owner: an audit of WebKit's HTML and JavaScript handling found places "very slow by orders of magnitude". The audit is
not in the repository; until it is, places are found by measuring (diary 2026-11-21-07), each fixed as a patch of our series
(ADR-0110) with a test that fails before it, and checked against the system's WebKit and Chrome Canary (their numbers as
theirs).

| Step | What | Status |
|---|---|---|
| P1 | Runs of sibling comments and text: parse, script append and removal quadratic (40,000 comments: 1.4 s; Chrome Canary 21 ms) | done: patches 0029–0030, 5 ms; styles checked on 21 mutations |
| P2 | Collections indexed at scattered positions (20,000 children: 363 ms; Chrome Canary 4.4 ms) and `normalize()` over many text nodes (375 ms; 9.5 ms) quadratic | done: patches 0031–0032, 3 ms and 1 ms; `normalize()` keeps the old steps when script can see them (mutation events, character data observers) |
| P3 | The audit's own places | not started: the audit is needed (put it in `docs/research/`) |
| P4 | JavaScript: `Array.prototype.includes` over 100,000 numbers 18.6 times Chrome Canary's | not started (JavaScriptCore's intrinsic) |

Not done: P3, P4; WebKit's layout tests (not in this checkout) not run on P1 or P2.
