---
status: accepted
date: 2026-11-18
---

# 0080 — The APIs of the browser shown are filled in natively, staged

Supersedes rule 2 of ADR-0074 ("identity, not features: an API WebKit lacks is never faked"). The owner, 2026-11-18: "we
implement natively the apis, but this is less of a priority right now and we should stage and schedule this implementation
effort in the roadmap and tasks of the repo".

## Decision

An API the browser shown has and WebKit lacks may be added to pages shown that browser, implemented natively by Sunset (as
driceroland/Search does for extensions), never as an empty stub: each one with what it does, its policy when a page can ask
something of the person or the system (white paper §9), and a test against the browser itself. Staged in roadmap 0046 D,
after the profiles and the network; error messages and codecs are studied in the same stage.
