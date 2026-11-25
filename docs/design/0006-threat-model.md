# 0006 — Threat model (as of 2026-11-25)

Status: **accepted**. Every security decision (ADRs) names the adversaries it answers. The evidence behind it:
docs/research/security-realism-2026-11-19.md; docs/research/credentials/; docs/research/threat-model-sota-2026-11-21.md (the
state of the art, field by field).

## What Sunset holds (assets)

| # | Asset | Where today | Protected by |
|---|---|---|---|
| D1 | Secrets for the person's accounts: a vault's passwords, codes, files; cookies and session tokens; HTTP auth answers | The vault (`SunsetCredentials`: its model, factors, lock, and `.svault` backups); WebKit's cookie jars; `CredentialPanel` (not kept) | Vault: its key, locked (ADR-0091). Cookies: sealed while Sunset is closed, 0600/0700 |
| D2 | The storage key and the recovery code | The data-protection keychain, the key wrapped by the Secure Enclave (`EnclaveKeyVault`) | The keychain's access group; the Secure Enclave; FileVault |
| D3 | Behaviour: history, sessions, open tabs, permissions answered, downloads list, recent files, favicons | `state.sqlite`, `session.sealed`, `library.sqlite` | Sealed payloads, their times and counts with them; a kind is a keyed tag (storage format 2) |
| D4 | The person's documents in Sunset | `Documents/` sealed files | Sealed |
| D5 | What WebKit keeps: network cache (full URLs), website data (IndexedDB, storage, service workers), HSTS, statistics | `~/Library/Caches`, `WebKit`, `HTTPStorages` | 0700 / 0600; cleared at quit for sites not kept (ADR-0081); caches out of backups; cookies and sites' storage sealed while Sunset is closed (2026-11-21) |
| D6 | The terminal's sessions: what programs print, scrollback, the shell's environment | Memory | The process |
| D7 | The person's input: keystrokes, pastes, clipboard | Memory, the system pasteboard | Clipboard gate; secure keyboard entry while a program reads a password; a warning before a risky paste |
| D8 | The device's capabilities a page can borrow: camera, microphone, screen, location, notifications | The system (TCC) and Sunset's answers per site | Permission policies (ADR-0061, ADR-0082) |
| D9 | Sunset's integrity: its code, its block lists, its settings | The app bundle (Developer ID, notarised, hardened runtime); `Blocking/`; `~/.config/sunset` | macOS; HTTPS for lists |
| D10 | **The engine's freshness** (Sunset WebKit only): its WebKit is at least as new as the last WebKit security advisory | The bundled frameworks, rebuilt by `Scripts/webkit.sh update` | Automated daily advisory & patch check (`webkit-check.yml`, ADR-0127) plus `AppEngineFreshness` age warning |
| D11 | **Release signing keys & build Mac** | Developer ID certificate, App Store Connect notary key, Ed25519 release-index main key (CI secret / signing Mac) and offline backup key (ADR-0125, ADR-0127) | Keychain / GitHub Secrets; offline backup key kept off build hosts; hardware custody planned |

## Who attacks (adversaries)

| # | Adversary | Can | Cannot (assumed) |
|---|---|---|---|
| A1 | **A web page** (and its frames, ads, trackers) | Run script in its world; post to Sunset's page-world handlers; show anything; ask for any permission; fingerprint | Reach Sunset's own world (`WKContentWorld`); forge `WKFrameInfo` while WebKit holds (see A10) |
| A2 | **What a terminal shows**: a program, a remote host over SSH, a file `cat`'d | Send any byte sequence; ask replies; write the clipboard (OSC 52) | Read the clipboard; reach the system except by ADR-0010's events |
| A3 | **Another program of the same user** (malware, a curious app, a compromised dependency of another app) | Read every file Sunset owns (0600 is the same user); log keys through event taps (if granted); read memory only with debugging rights (the hardened runtime blocks attaching) | Read the data-protection keychain item (its access group); read the Secure Enclave key |
| A4 | **Someone with Sunset's files but not the running Mac**: a backup (Time Machine, a cloud backup), a copied `~/Library`, a sync folder's provider, a stolen disk without FileVault | Read what is in the clear; copy, replay, delete, roll back files | Open sealed payloads without the key; open a vault without a factor |
| A5 | **Someone at the unlocked Mac** (borrowed, shoulder-surfing, a screen share) | Use the open app; see the screen; capture it (share, screenshots) | Open a locked vault; see windows excluded from capture |
| A6 | **The network**: a hostile Wi-Fi, an ISP, a proxy | See names (DNS), timing, sizes; tamper with http; block | Read or alter https (WebKit's TLS); alter lists fetched over https |
| A7 | **The sync or backup provider**, honest but curious or malicious | Store, withhold, reorder, roll back, delete Sunset's files | Read or forge sealed records (AEAD, the vault key) |
| A8 | **The supply chain & update feed**: dependencies, GitHub release feed, build Mac, block-list sources | Tamper with GitHub release assets/metadata, serve stale/frozen feeds, or alter unsigned inputs | Forge Developer ID + Apple notarisation signatures, or forge Ed25519 `release-index.json.sig` without a release key; dependencies are revision-pinned |
| A9 | **An extension** the person installs | What its permissions give, in WebKit's extension host | What Sunset's own policy refuses (ADR-0113); CRX3 signatures and Mozilla host checks enforced before load |
| A10 | **A compromised WebContent process** (a WebKit exploit) | Act as the page with WebKit's sandbox's rights; maybe lie in messages to Sunset; **read what every frame of its page holds, cross-site frames included** (WebKit's site isolation is off in both builds: a cross-site frame shares its embedder's process) | Leave WebKit's sandbox without a second exploit |

**Out of scope:**
- root or the kernel;
- someone with the person's login password at the Mac (they open the Keychain; the vault's own factors remain);
- hardware attacks;
- a person who chooses to export their secrets.

## Boundaries

1. **Page world ↔ Sunset's handlers.** Every message is hostile. The origin comes from `WKFrameInfo`, never from the body.
   Bodies are bounded (ADR-0067), and answers are what a page may know (ADR-0089).
2. **Sunset's content world ↔ the page.** Sunset's own scripts (sign-in watch, fill) read the DOM. The page cannot call them
   or see them, but it shapes the DOM they read (hidden fields, look-alike forms).
3. **The terminal's bytes ↔ the host.** ADR-0010's policy table; a bounded event queue.
4. **Sunset ↔ the disk.** Sealed records; the vault sealed by its own key; WebKit's stores sealed at quit.
5. **Sunset ↔ the network.** WebKit's loads; Sunset's own fetches (lists, icons) through `PublicAddress`/`FetchDelegate` and the profile's store.
6. **Sunset ↔ providers** (sync, backup, restore). Sealed `.svault` bytes only; Argon2id + AEAD authenticated header/payload; anti-rollback for sync.
7. **Sunset ↔ the system.** Keychain, Secure Enclave, TCC, the pasteboard (`PasteboardImage` bounded to 16M px), notifications, Launch Services (links, downloads), and App-Sandboxed Quick Look preview/thumbnail extensions (read-only).
8. **Sunset ↔ the updater & release feed (ADR-0122, ADR-0125, ADR-0127).** Host-pinned HTTPS (`UpdateURLPolicy`), mandatory Ed25519-signed expiring `release-index.json` (builds ≥ 829), bounded LZMA/SSDLTA2 delta staging, and mandatory Developer ID + team + bundle-ID + notarisation + build-order checks before bundle swap.

## Threats, mitigations, gaps

| Threat | Adversary | In place | Gap → where |
|---|---|---|---|
| A page tells Sunset from Safari, tracks it | A1 | ADR-0089 (nothing of Sunset's in the page), ADR-0051/-0074 | Safari's APIs missing; WebAuthn's inconsistent answer |
| A page drives Sunset's handlers (fake clicks, frames, shares) | A1, A10 | Pull, not push; origin from `WKFrameInfo`; bounded (ADR-0067, ADR-0089) | Handlers' fuzzing; a check that a compromised WebContent cannot claim another origin (WebKit's site isolation: to read) |
| A page phishes a fill, reads secrets from hidden fields | A1 | Filling in Sunset's own world, on a click, for one origin checked as it fills; the page's made-up events not believed (ADR-0094) | ADR-0094: the person's act, same origin, shown fields, suggestions drawn outside the page |
| A page abuses permissions (camera, notifications, pop-ups, sound) | A1 | Answers per site, asked on gesture, limits (ADR-0061, ADR-0077) | One table of every permission's policy and its test |
| A hostile page exploits WebKit | A1 → A10 | WebKit's sandbox, Apple's updates; HTTPS upgrade, a hardened mode and GPC as settings (`WebProtection`) | A hardened level without JIT, measured |
| Escape sequences act outside the screen | A2 | ADR-0010, ADR-0026, ADR-0027: no title, clipboard or font reports, no DECRQSS, bounded replies, REP capped, OSC 7 never looked up | Fuzz targets with a known-CVE corpus (vt-houdini); C1 controls inside UTF-8 dropped by default since 2026-11-21 (a setting turns them on) |
| A paste runs commands the person did not see | A1/A2 | Bracketed paste; a warning naming each risk before the paste (`PasteWarning`) | — |
| Keys logged while typing a password in the terminal | A3 | Secure keyboard entry while the program reads a password (`SecureInput`) | A password asked on another host through SSH is not seen |
| Behaviour read from Sunset's files | A3, A4 | Sealed payloads, their times and counts sealed too, kinds as keyed tags; 0600/0700, `secure_delete`, the WAL truncated | — |
| Session tokens and sites' data read from WebKit's folders | A3, A4 | Cleared at quit for sites not kept; caches marked out of backups; cookie jars and sites' storage (IndexedDB, local storage, service workers, statistics, HSTS) sealed at quit, after the network process has put its storage to rest and ended, and opened at launch | A3 while Sunset runs (all in the clear then); a crash leaves them in the clear until the next quit; extensions' storage (`WebExtensions`) not sealed |
| The storage key taken | A3, A4 | The data-protection keychain, the Secure Enclave wrap; FileVault | — |
| A vault opened | A3, A4, A5 | Factors, the lock (idle, sleep, screen lock, another user, quit, last window), zeroed key buffers (ADR-0091); the window out of capture while it shows an unlocked vault; a secret copied leaves the clipboard after 90 s | The entries' text is held as Swift strings while unlocked (not zeroed) |
| Clipboard secrets left behind | A3, A5 | Clipboard gate | Concealed type, clearing |
| Screen captured with secrets | A5 | — | `sharingType = .none` for the vault; Sunset's own share skips those windows |
| A sync provider rolls back, withholds, reorders | A7 | — | Per-device logs with sequence numbers; each device remembers the highest seen per device and refuses older; heads sealed and chained (ADR-0095, to add) |
| Backups open to whoever holds them | A4 | Sealed records | A sealed backup of everything (realism study) |
| Code injected into Sunset | A3 | Developer ID, notarised, the hardened runtime, library validation | — |
| Lists or updates altered or frozen | A6, A8 | Lists over HTTPS; updater enforces host-pinned HTTPS, mandatory Ed25519-signed expiring `release-index.json` (builds ≥ 829), hash-verified archives/delta TOCs, Developer ID + team + notarisation + build order | Hardware-held release key + separate offline root rotation key (N-S3); SLSA provenance + CycloneDX SBOM in `release.yml` (N-S7) |
| Build Mac or release key compromised | A8 | Developer ID + Apple notarisation required independently of `release-index.json`; offline backup key stored off build hosts | Move signing key into Secure Enclave/HSM and gate `RELEASE_INDEX_KEY` behind a protected GitHub Environment (N-S3) |
| Hostile `.svault` backup or credential import | A4, A7 | Bounded Argon2id parameters, authenticated AEAD header/payload, fuzzed CSV/Bitwarden JSON parsers | Dedicated fuzz target for `.svault` container parser; recurring clean-Mac restore drill |
| Quick Look extensions parse untrusted Markdown | A3, A4 | App-Sandboxed, read-only preview & thumbnail extensions (`AemiMarkdown` safe HTML subset) | — |
| Forged or MITM browser extension (`.crx`/`.xpi`) | A1, A6, A9 | CRX3 protobuf RSA/ECDSA + `crxID` verified before unpacking; arbitrary-host `.xpi` links refused (only `addons.mozilla.org` HTTPS without redirects accepted) | Full Mozilla PKCS#7/COSE `.xpi` signature verification for local/store `.xpi` files |
| A download runs unchecked | A1 | Quarantine marked on hidden temp file before atomic rename (Gatekeeper) | — |
| An extension oversteps | A9 | ADR-0113: granted at install only, in words (header rewriting named), nothing later, no native messaging; WebKit's permission model | A prompt for later requests (refused today); an audit of each API in WebKit |
| Sunset WebKit runs a WebKit with known bugs | A1 → A10 | `Scripts/webkit.sh update` + automated daily `webkit-check.yml` advisory check & local build/release scheduler (ADR-0127); `AppEngineFreshness` warns when engine is weeks old | — |
| Sunset WebKit started with planted loader variables | A3 | Hardened Runtime without `allow-dyld-environment-variables` (ADR-0123); bundled WebKit linked via `@rpath`; `DYLD_*` scrubbed from terminal shells | — |
| A site tells Sunset is WebKit whatever it shows | A1 | `AgentScript`: identity, `userAgentData`, `window.chrome`, Safari-only objects removed, native-looking functions, no native HLS (docs/research/impersonation-beyond-identity-2026-11-21.md) | Engine error messages and stack traces cannot be made V8's or SpiderMonkey's: impersonation is for sites that gate on the user agent, not against fingerprinting |
| An extension's fill menu clicked through an invisible overlay (DOM-based clickjacking) | A1 | Sunset's own fill UI is outside the page (ADR-0094) | Extensions the person installs are as exposed as in other browsers; Sunset's fill: exact origin by default, subdomains on the person's choice |
| Data lost by Sunset itself (safety) | — | Atomic writes, unreadable rows never overwritten, unsaved edits kept (ADR-0038), sealed `.svault` automatic quit backups + printable QR emergency sheet | Recurring clean-Mac restore drill |

## Accepted residual risks (with review expiry)

| Risk | Owner | Mitigation today | Review / expiry date |
|---|---|---|---|
| `HIGH-06`: WebKit stores exist in clear while Sunset is running (A3) | Maintainer | Cleared at quit for non-kept sites; sealed at quit; hardened runtime blocks debugger attach | 2027-02-25 |
| `LOW-01` / `N-S5`: Main app not App-Sandboxed (terminal + vault share process) | Maintainer | Swift 6.4 strict memory safety, hardened runtime, WebKit isolated; XPC Vault + Decoder separation queued (Sprint 2) | 2027-02-25 |
| `N-S6`: WebKit site isolation off in both builds (A10) | Maintainer | Hardened mode without JIT available; tracking upstream WebKit Site Isolation readiness | 2027-02-25 |

## How it is kept

- Every new ADR touching data or untrusted input names its rows here, and adds rows when it creates a surface.
- A row's gap closes with a red test first (white paper §9).
- Reviewed when a stage of docs/design/0007 ends, and when a row changes.
