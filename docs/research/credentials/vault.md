# Sunset's own vault (2026-11-19)

A design to put to the owner: what is possible and what it costs. Nothing here is decided until ADR-0090 to ADR-0092 are
accepted.

## The scope

- Credentials are a feature scope, like `scopes.tabs`: off until the person turns it on (`credentials.enabled`).
- Off means:
  - no vault file;
  - no fill script in pages;
  - no menu items;
  - nothing in Settings beyond the switch.
- Turned off again later, the vault stays on disk, closed. Removing it is a separate act, which offers a backup first.
- One vault or several, each with a key of its own: Personal, Work, one shared through a folder. A profile may name its
  vault, or none.

## The store

- One SQLite file per vault, `~/Library/Application Support/Sunset/Vaults/<id>.sqlite`. It is Sunset's own store
  (SunsetStorage, `secure_delete`, the WAL truncated, 0600 in 0700: 0051 A and B).
- It is not the app's state database: the vault opens and closes on its own.
- Nothing in the clear but what the store itself needs, which is 0051 C's rule from the start:
  - a random 128-bit record id;
  - a record version;
  - the sealed payload.
- Kinds, titles, sites, times and sizes are all inside the payload. Rows are found by an index held in memory while the
  vault is open.
- Records:
  - an entry (one row per version: the newest current, the others its history);
  - a template;
  - an attachment's manifest;
  - an attachment's chunks;
  - a tombstone.
- Sealing: `Seal` as today (ChaCha20-Poly1305, a fresh nonce, the identity bound in). Each purpose has a key derived from
  the vault key (HKDF): entries, attachments, index, sync. An attachment has a random key of its own, held in its sealed
  manifest, so it can be re-keyed or shared alone.

## The keys

- The vault key: 32 random bytes, never written in the clear. It is wrapped once by each unlock factor the person sets;
  any one of them opens the vault (or two, if the person asks for that).

| Factor | How it wraps | Probed |
|---|---|---|
| Master password | Argon2id (`AemiArgon2`; parameters chosen by measuring, roughly 0.5–1 s on this Mac) → a key-encrypting key | Argon2 exists in Aemi (read); not measured yet |
| Touch ID / this Mac | ECDH with a Secure Enclave key under `.biometryCurrentSet` → HKDF → KEK | Made ad hoc signed (diary 2026-11-19-06) |
| Recovery code | 32 random bytes, written as words or groups of characters; shown once, printable as an emergency sheet | `StorageKey`'s recovery code exists for the app's store |
| A hardware key | FIDO2 hmac-secret / PRF output, PIV ECDH, or OTP HMAC → HKDF → KEK ([hardware-keys.md](hardware-keys.md)) | Not probed: no key here |

- Changing the master password rewraps the vault key: nothing is resealed.
- Rotating the vault key, for a person who thinks a factor leaked, reseals every record.

## Locking

- **Locks:**
  - at quit;
  - after an idle time (a `Runtime` clock, never a raw timer);
  - when the screen locks or the Mac sleeps (`com.apple.screenIsLocked`, `NSWorkspace.willSleepNotification`);
  - when the last window of a profile using it closes;
  - by hand (a menu item, a key).
- **Locked means:**
  - the vault key and the decrypted index are dropped;
  - the fill script answers nothing;
  - a page's prompt waits for the unlock sheet.
- **Memory:** Swift does not promise that a secret is wiped from memory. The vault key and passwords would live in a buffer
  of their own: locked against swapping with `mlock`, zeroed when freed, never a `String` until they are shown or filled.
  A password filled into a page is in WebKit's memory, beyond Sunset's reach; say so.
- **Clipboard:** a copied secret carries `org.nspasteboard.ConcealedType` and `TransientType`. It is cleared after a delay
  if the clipboard's `changeCount` has not moved since (Sunset's clipboard gate, `ClipboardGateTests`).
- **Screen:** the vault's windows use `NSWindow.sharingType = .none`, so screen sharing and screenshots get no pixel of
  them. Sunset's own tab share already captures windows, so it must exclude them too.

## Entries

An entry is a list of fields, laid out in sections, made from a template and then free to differ: fields added, removed,
moved, renamed.

**Templates.** Shipped:
- Login;
- Card;
- Identity;
- Secure note;
- Software licence;
- SSH key;
- Wi-Fi;
- Bank account;
- Passport;
- API key;
- Server.

The person's own templates are records like the shipped ones. Changing a template asks whether to apply the change to the
entries made from it; an entry keeps its own differences either way.

**Field types**, each with its constraints and how it shows:

| Type | Constraints | Shows as |
|---|---|---|
| Text, multi-line text | required, min/max length, a pattern (regex, AemiRegex) | plain |
| Concealed (password, PIN, secret) | as text, plus a generator recipe; password history kept | dots, revealed on hover or a key; strength shown |
| One-time code | an otpauth URI or its parts ([one-time-codes.md](one-time-codes.md)) | the current code, a countdown, the next code |
| URL (many per entry) | scheme allowed; a match rule each (registrable domain, host, exact, prefix, regex, never) | the site's icon; fill target |
| Email, phone | the format | a link |
| Number, money | min/max, decimals, currency | localised |
| Date, month-year (expiry), time | ranges, "in the future" | localised; warns before expiry |
| Choice, multiple choice | the options | a menu |
| Toggle | — | a switch |
| Card number | Luhn, network from its prefix | grouped, the network's mark |
| Reference | to another entry's field ("the same password as …") | resolved at use |
| File | size limit, types | an attachment (below) |
| SSH key | key type | public part copyable; agent use later |
| Address | parts by country | formatted |

**Constraints** are checked as the person edits. A failure blocks a save only for `required`; the rest warn. **Layout**:
sections, each with a name and an order; a field's width (full or half); hidden-by-default fields. The layout is part of the
template, and an entry may override it.

**Notes** are Markdown (AemiMarkdown, as Sunset's documents), one per entry, sealed with it.

**Files** are attachments:
- chunked (1 MiB), each chunk a sealed record;
- a size limit per file and per vault, set by the person;
- previewed inside Sunset only. Quick Look would need a decrypted temporary file, which is refused (§9).
- Exported by hand, with a warning.

**History.**
- Every save keeps the previous version, up to a count or an age (the person's choice).
- Concealed fields keep their own history with dates.
- Restoring a version makes it the newest.

**Search.** Over the decrypted in-memory index while unlocked:
- titles, usernames, sites, tags, notes;
- never concealed values.

Measured at 10,000 entries before it is called done.

**Folders and tags**, favourites, and the site's icon, which is fetched through the profile's own data store, never a third
party.

**The generator.**
- Characters, words (a list to choose), or a PIN.
- Honours a page's `passwordrules` attribute when there is one (Safari does).

**Health**, all local:
- reused, weak, old;
- sites known to offer passkeys or one-time codes.

A breach check (Have I Been Pwned's k-anonymity range API) only if the person turns it on, since it talks to a third party.

## Policies (white paper §9), each with a test

| What can ask | Policy |
|---|---|
| A page wanting a fill | Never without the person's act (a click on Sunset's suggestion, a key), unless they allow automatic fill for an exact match; never into a frame whose origin differs from the entry's site; never into a field not shown; not on http without a warning |
| A page's form sent with a password | Sunset offers to save (rate-limited, once a page); never saves silently |
| A page's `passwordrules` | Read only to shape a generated password; never trusted to weaken the generator's minimum |
| Opening the vault | Only the person (sheet, Touch ID, key); a page cannot raise the unlock sheet by itself more than once a page |
| An attachment opened | Inside Sunset; no decrypted file outside the vault without the person's export |
| Sync data arriving | Opened only if it seals with the vault key and its record ids; anything else is set aside, reported, never merged |
