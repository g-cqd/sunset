# Sunset and Sunset WebKit sharing their data (note n77, task t152)

The owner, 2026-11-21: "find a way for Sunset and Sunset WebKit to share the same data". What each build keeps where, what
can be shared safely, and a proposal. Measured on this Mac and read in the code (Sunset's and WebKit's, our base 944f9ff672).

## What each build keeps

| What | Sunset (`studio.aemi.sunset`) | Sunset WebKit (`studio.aemi.sunset.webkit`) | Who writes its format |
|---|---|---|---|
| Sunset's store: session, documents, history, zoom, permissions, downloads, extensions' packages | `~/Library/Application Support/Sunset` (77 MB) | `…/Sunset WebKit` (68 MB) | Sunset (`StoragePlaces`, by bundle identifier) |
| The key that seals it | data-protection keychain, access group `NP94WB3P75.studio.aemi.sunset` | access group `NP94WB3P75.studio.aemi.sunset.webkit` | Sunset |
| Settings | `~/.config/sunset` | `~/.config/sunset-webkit` | Sunset |
| WebKit's website data: cookies, IndexedDB, local storage, service workers, caches | `~/Library/WebKit/studio.aemi.sunset` (2.8 GB) | `…/studio.aemi.sunset.webkit` (846 MB) | **WebKit**, each its own version |
| Extensions' storage | inside WebKit's folder | inside its own | WebKit |

## What can be shared

| Part | Safe to share? | Why |
|---|---|---|
| Settings | Yes | One file, one reader (Sunset's code, the same in both builds) |
| Sunset's store | Yes, with care | Same code reads it; both builds the same Sunset version when released together. Two running at once would write the same SQLite files: SQLite handles it (WAL), but the session file is rewritten whole by whichever quits last |
| The sealing key | Yes | One keychain access group in both entitlements (both are ours, same team); the provisioning profiles must allow it |
| **WebKit's website data** | **No** | A newer WebKit upgrades stores in place; an older one then refuses them **by crashing on purpose**: `SQLiteIDBBackingStore::migrateIDBDatabaseInfoTableIfNecessary` ends in `RELEASE_ASSERT(metadataVersion < currentMetadataVersion)` (read 2026-11-21). The network cache is versioned (`NetworkCacheStorage::version = 18`) and thrown away on mismatch. Today both builds' IndexedDB files read `user_version 0`, but nothing promises it stays so: Sunset WebKit runs WebKit's main, months ahead of macOS's |
| Extensions' storage | No | Inside WebKit's data |

## Proposal

1. **Share Sunset's own data**: settings, the store (session, documents, history, site settings, downloads, extensions'
   packages and grants), one sealing key. Both builds point at `~/Library/Application Support/Sunset` and
   `~/.config/sunset`, and use one keychain access group (`…studio.aemi.sunset`). Sunset WebKit's existing data is merged
   once (its documents and history added, the rest kept where it differs from Sunset's).
2. **Keep WebKit's website data apart**, for the crash above. To carry sign-ins across, copy **cookies only**, one way and
   on the person's request (Settings ▸ Privacy: "Bring cookies from Sunset"): cookies are an HTTP format both WebKits read
   through `WKHTTPCookieStore` (`getAllCookies`, `setCookie`), never the files.
3. **One at a time**: if both run at once, the second asks to quit the first (both would write the session), or opens its
   own windows without a session of its own (to decide).

Not done: the provisioning profile change (a shared access group needs both App IDs to list it); what to do when both run;
the merge of today's two stores. Waits for the owner's choice between this and keeping them apart.
