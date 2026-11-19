---
status: done
blocked-by: nothing
date: 2026-11-18
---

# 0056 — (superseded by 0058) Where everything stands, and its order (the owner's note n48)

Every note (n1–n49), task and request of the session reviewed on 2026-11-18 in the evening. Done items are in the diary
(2026-11-18-04, -05) and their roadmap entries; this lists what is open, in the order it will be done: quick wins first.

## Done today, not seen on screen (the owner to try)

The copy glyph's answer; the press of glyph buttons; full screen (corners after it, edge-to-edge content, splits); the
window's blur over its material; WebKit's data choices (the site panel's "Keep its data", a profile's "Between runs");
the address field while typed in (n41); the crash's likely cause held off (n46: a hover kept while a menu is open, not
reproduced).

## Stage 1 — quick wins (hours)

| What | Note / task |
|---|---|
| The tab menu without Tab Settings | n47 (part), t77 |
| New Profile apart from the profiles' own buttons; each profile in a section of its own | n39, n38 (part), t69 |
| Toggles and controls on the trailing edge in popovers and folds (the site panel first); one rule and one symbol for More and folds, every occurrence listed and fixed | n45, t75 |
| Proxy: a check on demand that pages go through it (a page of our own fetched through it, the address it sees compared) | n37, t68 |

## Stage 2 — features (a day or two each)

| What | Note / task |
|---|---|
| A floating bar when the sidebar is off; the page's address row floating over its top | n41, n42, roadmap 0055, t72 |
| A tab playing sound, using the microphone or the camera shows it, and mutes it from there and from the site panel | n47, t77 |
| Each site: defaults, the sites with rules of their own (each folds open on what differs), patterns of hosts or addresses; every setting of the site panel there | n40, t70 |
| Profiles' settings: a level of their own, or a selector "all profiles / this profile" filtering what a profile can set | n38, n1, t69, t9 |
| Share a Sunset tab of any kind in screen sharing (ScreenCaptureKit's picker, beside screens and windows), other profiles' by a setting | n49, t78 |

## Stage 3 — security and storage (0051)

| What | Task |
|---|---|
| C: less in clear (times, counts, kinds in the payload; row keys by HMAC) | t48 |
| D: recovery code KDF (Argon2id, our Aemi implementation) if it can be typed | t48 |
| E: exports sealed by default | t48 |
| I: WebKit's stores sealed (an encrypted image opened with the Keychain key), with performance, stress and benchmark runs against the stores in the clear (release, percentiles) before any decision | t51, t59 |
| F: Developer ID, hardened runtime, Secure Enclave wrapping | t49: **blocked on the owner's certificate** |

## Stage 4 — larger roadmaps

| What | Task |
|---|---|
| 0050: profiles' own settings, Reload As (needs the owner's refinement) | t9, t10 |
| 0047 G: the rest of the settings' wording | t24 |
| 0046: DNS over HTTPS/TLS/QUIC, extensions, impersonation beyond identity | t13–t15 |
| 0048: WebKit's private network interfaces, then the own engine spike (ADR-0078: only if shown better) | t27, t28 |
