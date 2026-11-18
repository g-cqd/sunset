# Storage audit, extended: what WebKit keeps beside Sunset (the owner's, 2026-11-18)

The owner's extended audit (note n23), kept here with every person's, company's and real datum removed at his asking (note
n24): no names, addresses, hosts, tickets, identifiers or tokens; hosts are described by kind. Claims until probed; what was
probed here is said below.

## What it found

Sunset's own sealed storage is as the first audit said (docs/research/storage-audit-2026-11-18.md): per-record AEAD, the key in
the Keychain, nothing of the payloads recovered; times, counts and the WAL's residue in clear (0051 A, B done since).

Beside it, **WebKit's own stores are in the clear**, and hold more than the sealed store:

| Store | Where (under `~/Library/`) | What is readable |
|---|---|---|
| Network cache | `Caches/<bundle id>/WebKit/NetworkCache/` (~51 MB) | ~880 responses with their full URLs (code hosting commits, an issue tracker's issues, internal tools' pages, a chat app's client), ~280 blobs of page, script and image content |
| HSTS | `Caches/<bundle id>/WebKit/HSTS/HSTS.plist` | the list of every HTTPS domain visited |
| Alternative services | `Caches/<bundle id>/WebKit/AlternativeServices/*.sqlite` (+ WAL) | HTTP/2 and HTTP/3 records per host, with times |
| Website data | `WebKit/<bundle id>/WebsiteData/Default/` (~920 MB) | per origin (names salted, origins recoverable from service worker registrations, IndexedDB and CacheStorage): IndexedDB (issues, mail metadata, chat data), LocalStorage (settings, analytics and session ids, one store's log ~95 MB), CacheStorage, service worker registrations with script URLs. The largest: a chat app (~720 MB), an issue tracker (~110 MB), a mail app (~90 MB) |
| Resource load statistics | `WebKit/<bundle id>/WebsiteData/ResourceLoadStatistics/observations.db` | ~75 domains with the time of the last interaction with each, and which third parties load under which sites (sign-in redirects, captchas, analytics) |
| Cookies | `HTTPStorages/<bundle id>.binarycookies` (0644), and a jar under `WebKit/<bundle id>/WebsiteDataStore/` | session tokens and CSRF tokens of signed-in services, device ids, account emails inside some cookies' values, a code host's user name |
| Preferences | `Preferences/<bundle id>.plist` (0600) | window frames, the screen's size |
| A development build's | the same places under `<bundle id>.dev` | the same kinds, smaller |

From these alone, without any key: who the person is (from the home folder's name), their accounts' emails, employers and
internal hosts, what they worked on (issue keys, commits viewed), the services used, a timeline of interactions over days, the
third parties that follow them, and live session tokens.

The binary: ad-hoc signed, no Team ID, no hardened runtime.

## Its recommendations, in its order

1. Critical: WebKit's cache and website data cleared on quit, or a non-persistent store; cookie jars encrypted or cleared on
   quit; the HSTS list cleared on quit.
2. High: 0700 on Sunset's support folder and both cache folders, 0600 on every `*.sqlite*`, `*.binarycookies`, `*.plist`; WAL
   hygiene (done for Sunset's own); resource load statistics cleared on quit.
3. Medium: times and counts sealed; Developer ID, hardened runtime, library validation, Secure Enclave wrapping; a memory-hard
   KDF for a typed recovery code.
4. Low: alternative services, the per-origin device id salts, the window frames in the preferences.

Its bottom line: "The sealed store protects the history index; the cache exposes the history itself."
