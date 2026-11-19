# The open security points, studied again (2026-11-19)

Each open point: what it would really take, what it is really worth against the threat model (docs/design/0006), and a
recommendation for the owner. Probes: diary 2026-11-19-06 and -07.

**Worth** is measured against adversaries A1–A9 of the threat model.

## Storage (roadmap 0051)

| Point | Realistic? | Cost | Worth | Recommendation |
|---|---|---|---|---|
| **t48 C** — times, counts, kinds in the sealed payload; row keys by HMAC; reseal | Yes. Every row is already opened at load (`SealedRows`); the one SQL use of the clear time is history's pruning, which moves to memory | 1–2 days; a one-time reseal on upgrade (measured on a large history) | Medium: hides behaviour (when, how often, how many) from A3 (other programs) and A4 (copies, backups) | **Do**, as "storage format 2", the same record layout the vault will use (id, version, sealed payload) |
| **t48 D** — a memory-hard KDF for the recovery code | Moot. The code is the random 256-bit key itself (Crockford base32, 2-character check); nobody types prose | — | None for the code | **Close D.** Argon2 (`AemiArgon2`) moves to the vault's master password (0091 C) and passphrase-sealed backups (below) |
| **t48 E** — exports sealed by default | Partly. An export only Sunset can read is a backup, not an export; today's are plain, 0644 | Hours for 0600 and a warning; a day for a sealed backup | Medium (A4) | **Split.** Exports stay readable, written 0600, with a warning. A **sealed backup** of all of Sunset's data, opened by a passphrase (Argon2id) or the recovery code: the format the vault's `.sunsetvault` uses (0095 A), one format for everything |
| **t49** — Developer ID, hardened runtime, library validation, Secure Enclave wrap | Yes, once the owner has a paid Apple Developer membership and its certificate. The work is mechanical: signing, `notarytool`, entitlements, an embedded profile. Notarisation checks for malware, not private API (SunsetPrivate calls Apple-signed WebKit, which library validation allows) | 1–2 days of scripts; then macOS asks again once for every permission (camera, microphone, screen) and maybe once for the Keychain item, since the app's identity changes | **High.** It is the gate of the Keychain's protection classes, iCloud, passkeys, the credential provider, Credential Exchange (0098); hardened runtime and library validation against A3 injecting code | **First among the external dependencies.** The Secure Enclave wrap needs no t49 (probed): do it with t48 C |
| **t51** — WebKit's stores sealed in an encrypted image | Technically yes: custom paths for every store (probed); the image is cheap (t59) | 3–5 days: hdiutil at launch, a crash leaving it mounted, the bundle's growth and compaction, moving ~920 MB in once, Spotlight and Time Machine | **Low.** FileVault is on (probed), and while Sunset runs the image is open to every process of the same user (A3). It covers only "Sunset closed" and copies of `~/Library` (A4) | **Do not build the image.** Cheaper and worth more: (1) the cookie jar sealed by Sunset at quit and restored at launch (`WKHTTPCookieStore`, public: to probe); (2) caches excluded from backups (`NSURLIsExcludedFromBackupKey`); (3) a profile's network cache in memory only, as a choice; (4) ADR-0081's clearing at quit (done) |
| **t59** — perf, stress, benchmark of sealing | Measured today: attach 0.36 s; SQLite commits 1.8× (34 µs); small files equal | — | Answers t51's question | **Close** with these numbers; stress runs only if t51 is ever built |
| **0051 G** — the cookie jar rewritten 0644 at quit | Done, not checked in Sunset (roadmap 0058 1.6) | Minutes | Defence in depth (`~/Library` is 0700) | Check once on the installed build |

## The terminal (roadmap 0012, ADR-0010)

| Point | Realistic? | Cost | Worth | Recommendation |
|---|---|---|---|---|
| The threat list | Yes | — | Needed by everything | **Done as a draft:** docs/design/0006-threat-model.md |
| Fuzz targets for the parser | Yes: the parser is a byte state machine with defined outcomes (ADR-0023) | 1–2 days for the targets; runs in CI only (AGENTS.md) | High (A2: output from a remote host or a file) | Do with 0005's oracles |
| The control socket's authentication | Yes (ADR-0022, peer credentials) | With remote control itself (0016, not built) | High once built | Keep it in 0016; no socket without it |
| Secure keyboard entry (not in Sunset) | Yes: `EnableSecureEventInput` while a password prompt has focus (Terminal.app's menu item) | Hours; automatic on a terminal's echo-off is a day | Medium (A3: keyloggers using event taps) | **Propose to the owner** |
| A warning for multi-line or control-character pastes (not in Sunset) | Yes | Hours | Medium (A1/A2: a page's clipboard copy run as commands) | **Propose to the owner** |

## The web

| Point | Realistic? | Cost | Worth | Recommendation |
|---|---|---|---|---|
| Per-navigation protections WebKit offers and Sunset does not set: HTTPS upgrade (15.2), Lockdown (13), `securityRestrictionMode` (26.4: no JIT, more memory tagging), Global Privacy Control (27) | Yes: public, per navigation (headers read, probed defaults) | Hours each, plus a site's and a profile's setting | **High** (A1: hostile pages, the network). The restriction mode makes many WebContent exploits harder at a speed cost that is to be measured | **Propose:** HTTPS upgrade with a warning page on by default (as Safari); a "hardened" level per site or profile (no JIT); GPC as a setting. Measure the no-JIT cost (Speedometer, release) before offering it widely |
| t13 — DNS over HTTPS/TLS/QUIC | Only by resolving ourselves behind a local proxy: the privacy context cannot pick the resolver (probed) | Large | Medium (A6: the network sees names; also hidden by iCloud Private Relay or a system DoH profile) | **After the above**; say in Help that a system DNS profile does it for the whole Mac |
| t27 — WebKit's private network interfaces | Probed working (proxy per store) | — | Per profile network separation | As planned |
| t14 — extensions | Yes (`WKWebExtensionController`) | Large | They are a new adversary (A9): each permission needs the policy table ADR-0010 has for sequences | Write their policy before the first extension runs |
| t98 / 0099 — Safari's APIs Sunset lacks, Apple Pay | Open (the sheet cancels, unread) | Unknown | Detection (impersonation), payments | As staged: on screen with the owner |

## Credentials (roadmap 0090–0099)

| Point | Realistic? | Notes |
|---|---|---|
| 0091–0096 — the vault, entries, codes, filling, backups, sync | Yes, all without t49 | Large in total. 0091 + 0092's model + 0093 is a usable first release (a few weeks); filling (0094) is where the risk is, and last of the first set |
| 0097 — hardware keys | PIV and OATH: yes; FIDO2 and OTP HMAC: to probe | Blocked on the owner's key |
| 0098 — Apple's side | After t49, and Apple's grant: Apple reviews the request against browser criteria (an address field at launch: Sunset's field is always there, ADR-0064) | The grant itself is not in our hands |

## What this leaves out of the plan before, and puts in

- **Out:** t48 D as written; t51's image; t59's further runs.
- **In:**
  - a sealed backup of everything (one format with the vault's);
  - the cookie jar sealed at quit;
  - caches out of backups;
  - per-navigation protections (HTTPS upgrade, a hardened level, GPC);
  - secure keyboard entry and a paste warning for the terminal;
  - fuzz targets;
  - an extension policy table;
  - the threat model itself, kept current.
