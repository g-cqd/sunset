---
status: not-started
blocked-by: nothing
date: 2026-11-18
---

# 0046 — Encrypted name resolution, extensions, and impersonation beyond identity

The owner, 2026-11-18, after roadmap 0045: "we might have in the roadmap to work on the topics of filling some spots for
the missing apis, errors messages and codecs depending on the browser impersonation we want to do, we can have a look
at https://github.com/driceroland/Search and how they do but we might want to work in priority on bringing support for
chrome and firefox extensions, with priority on supporting proxy apis and even more top priority with supporting dns
over https/tls/quick (we might want to have a look into https://github.com/g-cqd/http for some network implementation
and promote them to one of our aemi repo, even in aemi itself maybe)". And on the two points 0045 left to him: "this
could be a setting", for each.

In his order. Each step starts with its questions and probes; nothing below is a claim yet.

| Step | What | Task | Status |
|---|---|---|---|
| A | DNS over HTTPS, TLS and QUIC for the pages (0022's note n75): study g-cqd/http for what it already implements, and whether it, or parts, belong in an Aemi package or Aemi itself; how a web view's name resolution can be reached at all (the open question of 0022) | t13 | not-started |
| B | Extensions, Chrome's and Firefox's, the proxy interfaces first (with 0022 W-f's `web.proxy`) | t14 | not-started |
| C | Extensions, the rest (0022's study t161) | t14 | not-started |
| D | Impersonation beyond identity: the missing APIs, error messages and codecs of the browser shown, studied from driceroland/Search; each one put in only where a page would not break for it (ADR-0074's rule 2 to be revisited with the owner) | t15 | not-started |
| S1 | A setting: a page's request to notify without a click asks the person (Chrome) or not (Safari, now; ADR-0067) | t16 | not-started |
| S2 | A setting: a page's service-worker `showNotification` is posted as its other notifications are | t17 | not-started |

S1 and S2 are small; the owner did not place them among A–D.

The owner, 2026-11-18 (later): roadmap 0047 comes before this one.

## First reading (2026-11-18; docs/research/network-dns-proxy-extensions-2026-11-18.md)

- A: the system's encrypted-DNS switch for an app's connections does not let Sunset choose the resolver (probed): Sunset
  must resolve names itself; the pages' names reach a proxy as names (probed upstream), so a gateway inside Sunset can.
- B: WebKit's extension engine has no `proxy` permission: Sunset provides `chrome.proxy`, as Search fills APIs in.
- A proposition (one gateway: Sunset's resolver, then direct, `web.proxy` or an extension's proxy) waits for the owner.
