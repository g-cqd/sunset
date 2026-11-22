---
status: in-progress
blocked-by: nothing
date: 2026-11-19
---

# 0094 — Filling and saving in pages

Research: docs/research/credentials/web-apis-and-payments.md. ADR-0094 (proposed). White paper §9: every row a policy with a test.

| Step | What | Status |
|---|---|---|
| A | Field finding in Sunset's world, every frame (autocomplete tokens, heuristics, open shadow roots); red tests on fixture pages | done 2026-11-22 for the main frame (`PasswordFill`, `PasswordFillScript`: autocomplete tokens, the text field before a password, visible fields only; red tests). Frames and shadow roots not |
| B | Matching (registrable domain with the PSL if accepted, else host; per-URL rules); homograph display | done 2026-11-22 (`LoginMatch`, `LoginSite`: registrable domain, exact host first, https entries not on http, look-alikes never); per-URL rules and homograph display not |
| C | Suggestions drawn outside the page; fill on the person's act; automatic fill for exact matches only if allowed; never hidden fields, cross-origin frames; http warned | done 2026-11-22: a popover under the field, on the person's click only, as typing would (input events), never a hidden field; seen in a test copy. Automatic fill and the http warning not |
| D | Saving: `SignInWatch` grows to read the username and password at sending; a bar outside the page; once a page; never in private windows | done 2026-11-22: offered after sending, at the field, Save / Update / Never for This Site / Not Now (`LoginSave`); never in private windows; seen. While locked not offered |
| E | New passwords: generated with `passwordrules`, kept as a draft before sending | done 2026-11-22: Use Strong Password under a new password's field (`NewPassword`, `fillNewPassword`): the page's rules, else the site's; filled into the password and its confirmation on a click; saved by the offer after sending. No draft kept before sending |
| F | Cards, addresses, emails, one-time codes; a card's security code never without a reveal | in-progress: one-time codes done 2026-11-22 (`CodeOffer`, `fillCode`: a field by token or name, or split in boxes); cards, addresses and emails not |

Not done: F's cards, addresses and emails; frames other than the main one; the hover seen on screen (a background copy gets no pointer).
