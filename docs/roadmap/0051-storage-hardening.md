---
status: in-progress
blocked-by: nothing
date: 2026-11-18
---

# 0051 — Storage hardening, from the owner's audit

The owner, note n22 (2026-11-18): "the following informations need to be persisted to the repo and staged and scheduled in the
roadmap with priority to be addressed as soon as possible". The audit: docs/research/storage-audit-2026-11-18.md. A and B done
first; the owner, later that day: the notes not started (n11, n13, n14, n16, n21) come before C–F, "as i'll have more findings
there to bring soon"; then C–F, then 0050.

| Step | What | Task | Status |
|---|---|---|---|
| A | The folder 0700, the databases and their WAL and SHM 0600, set on every open and on files made | t47 | done: 0700/0600 on open and made; seen on a test copy |
| B | No residue: `secure_delete` on, the WAL checkpointed and truncated on close and after deletes (history cleared) | t47 | done: `secure_delete` on, the log truncated on quit and after a kind is cleared; seen 0 bytes after quit |
| C | Less in clear: times and counts inside the sealed payload, or coarse; opaque ids for kinds; row keys by HMAC with a key of their own; a migration that reseals | t48 | not-started |
| D | The recovery code: what it is (random, or typed); a memory-hard KDF (Argon2id, our own, in an Aemi package) if it can be typed | t48 | not-started |
| E | Exports: sealed by default, or opt-in with a warning | t48 | not-started |
| F | Signing: Developer ID, hardened runtime, library validation; a Secure Enclave key wrapping the storage key | t49 | not-started (needs the owner's certificate) |

The extended audit (note n23; docs/research/storage-audit-webkit-data-2026-11-18.md, every real datum removed, n24): WebKit's own
stores beside Sunset's (network cache, website data, cookies, HSTS, resource load statistics, alternative services) are in the
clear and hold more than the sealed store. Added, and first among C–J once the notes not started are done:

| Step | What | Task | Status |
|---|---|---|---|
| G | WebKit's folders and files Sunset's own only: 0700 on `Caches/<id>`, `WebKit/<id>`, `HTTPStorages/<id>`, 0600 on the cookie jar, at launch and at quit (`WebKitFolders`) | t50 | done: the folders hold; the jar is rewritten 0644 at quit and is kept only by `~/Library/HTTPStorages` (0700). Defense in depth only: `~/Library` is 0700 already |
| H | What WebKit keeps between runs (ADR-0081): `web.keep.cache`, `.traces` (kept), `.siteData` (kept for the sites chosen or signed in to); each profile may set its own; the site's panel keeps a site; Each site lists it | t50 | done: probed per site in a store of its own; not seen in the app; the first quit with it keeps the visited sites holding cookies and clears the others' (trackers') data |
| I | Probe whether WebKit's stores can be sealed at all (a data store at a custom location on an encrypted volume or a sealed disk image, mounted with the Keychain's key; `WKWebsiteDataStore(forIdentifier:)`'s location); the own engine (0048) as the other way | t51 | not-started |
| J | A development build's data (`.dev`) under the same rules | t50 | done for G (the running bundle's id); not run as `.dev` |

Re-studied 2026-11-19 (docs/research/security-realism-2026-11-19.md, roadmap 0100, ADR-0100 proposed): C kept as "storage format 2"; D moot (the recovery code is a random 256-bit key: no KDF); E split (exports 0600 with a warning; a sealed backup of everything); F the gate of Apple's side; I's image not worth building (FileVault on; open while Sunset runs), the cookie jar sealed at quit and caches out of backups instead. Awaiting the owner.

Each step: red first (a test reading the modes, the WAL, the clear columns), the cost measured where it touches the hot path
(history writes, launch).
