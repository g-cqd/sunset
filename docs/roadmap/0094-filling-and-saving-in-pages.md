---
status: not-started
blocked-by: 0092; the owner's word on the Public Suffix List and Apple's password-manager-resources (§8)
date: 2026-11-19
---

# 0094 — Filling and saving in pages

Research: docs/research/credentials/web-apis-and-payments.md. ADR-0094 (proposed). White paper §9: every row a policy with a test.

| Step | What | Status |
|---|---|---|
| A | Field finding in Sunset's world, every frame (autocomplete tokens, heuristics, open shadow roots); red tests on fixture pages | not-started |
| B | Matching (registrable domain with the PSL if accepted, else host; per-URL rules); homograph display | not-started |
| C | Suggestions drawn outside the page; fill on the person's act; automatic fill for exact matches only if allowed; never hidden fields, cross-origin frames; http warned | not-started |
| D | Saving: `SignInWatch` grows to read the username and password at sending; a bar outside the page; once a page; never in private windows | not-started |
| E | New passwords: generated with `passwordrules`, kept as a draft before sending | not-started |
| F | Cards, addresses, emails, one-time codes; a card's security code never without a reveal | not-started |

Not done: everything.
