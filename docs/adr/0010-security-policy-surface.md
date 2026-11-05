---
status: proposed
date: 2026-11-05
---

# 0010 — Every untrusted action has a policy

Surface to specify before implementing it: clipboard read/write (OSC 52), file reads and shared memory by graphics commands (`t=f`, `t=t`, `t=s`), hyperlink schemes (OSC 8), title and notification injection, paste (bracketed, with a warning for control characters), query replies (do not leak data), control socket authentication (peer credentials), image and scrollback quotas, child environment and resource limits. Defaults deny or ask; each has a test, written red first.
