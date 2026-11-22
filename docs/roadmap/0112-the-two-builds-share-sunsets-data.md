---
status: done
blocked-by: nothing
date: 2026-11-22
---

# 0112 — Sunset and Sunset WebKit share Sunset's data (the owner's note n77; ADR-0114)

| Step | What | Status |
|---|---|---|
| A | Sunset WebKit keeps Sunset's store, settings and key; its own places of before still found (`StoragePlaces.former`) | done 2026-11-22: `StoragePlacesTests`, red first |
| B | One keychain group: Sunset's first, its own second (`make-webkit-app.sh`) | done 2026-11-22: the entitlements checked with `plutil`; a Secure Enclave key made by one executable used by another (probe, ad hoc signed) |
| C | One at a time: the second opened offers to quit the other, or itself (`OtherBuildAtLaunch`) | done 2026-11-22: the builds that share decided by `StoragePlaces.sharers` (tested); the alert not seen (running it would have offered to quit the owner's own Sunset) |
| D | Its store of before merged once: documents under their ids, history joined, its folder untouched (`FormerStoreMerge`) | done 2026-11-22: `FormerStoreMergeTests`, red first, folder compared byte for byte |
| E | "Bring cookies from Sunset", one way, on request, through `WKHTTPCookieStore` | done 2026-11-22: the jar read (`BinaryCookies`, `CookieJars.read`), red first against a jar WebKit wrote; File ▸ Bring Cookies from Sunset built, not run |
| F | Seen with the owner's own builds: the shared key opening under Developer ID, the merge of his store, the alert | done 2026-11-22 (build 717): key, merge, folder untouched, one at a time seen (diary 2026-11-22-05); the alert and the cookie count not reported |

Not done: the alert and Bring Cookies not seen by us (the owner used them; no report). The blocking lists are compiled again by each engine over the other's (roadmap 0113 would end it). Sunset WebKit's settings of before (`~/.config/sunset-webkit`) are no longer read, and are not merged.
