---
status: accepted
date: 2026-11-18
---

# 0081 — What WebKit keeps between runs: kept by default, a site's data kept only when chosen or signed in to; app-wide, a profile may differ

The owner's extended audit (note n23; docs/research/storage-audit-webkit-data-2026-11-18.md) found WebKit's own stores in the
clear beside Sunset's sealed one. His answers, 2026-11-18: the network cache "Keep"; the HTTPS list, the interaction log and
the HTTP/3 records "Keep"; cookies and website data "Keep, but per-site exceptions: kept for sites you choose (or that you've
signed in to), cleared for the rest on quit"; scope "Per profile now", "both should be possible" (app-wide, a profile may
differ), "also can't we encrypt everything ?".

## Decision

1. Three choices, app-wide in `web.keep`, each a profile may set otherwise:
   - `cache` (WebKit's disk, memory and fetch caches): `keep` (default) or `clearOnQuit`.
   - `traces` (HSTS, resource load statistics, alternative services, ad click and private click measurements): `keep`
     (default) or `clearOnQuit`.
   - `siteData` (cookies, local and session storage, IndexedDB, WebSQL, service workers, file system, media keys, hash
     salts, credentials): `keep`, `keepChosen` (default) or `clearOnQuit`.
2. With `keepChosen`, a site's data is kept when the site is on the kept list (its panel: "Keep this site's data"; Settings
   › Web › Each site), else cleared when Sunset quits. A site is put on the list by itself when a password is sent from one
   of its pages (a form with a password field submitted): generic, no list of sites. A site is a host and its subdomains
   (`SiteRules`).
3. Turning `keepChosen` on (and the first run with it, the default) does not sign the person out: every site holding cookies
   then is put on the list first. Nothing already there is lost by the change.
4. Clearing happens before Sunset ends (the quit waits for WebKit's answer, at most a few seconds) in every profile's store;
   a private window's store is not persistent and has nothing to clear.
5. Encrypting all of it (the owner's question) is step 0051 I: WebKit writes these files itself; whether its stores can live
   on an encrypted image Sunset opens with its Keychain key is probed before anything is promised. Such encryption protects
   copies, backups and a disk read elsewhere; while Sunset runs, a program of the same user reads the files as it reads any
   browser's.

## Consequences

- A site the person uses without a password (a magic link, a passkey, an SSO redirect) is cleared unless put on the list; its
  panel says so after the first quit that clears it (to do with H).
- Per site lists are app-wide (one list for every profile) until per-profile site rules (roadmap 0050).
