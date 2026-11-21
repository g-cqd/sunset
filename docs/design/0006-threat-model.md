# 0006 — Threat model (draft, 2026-11-19; refined 2026-11-21)

Status: **draft for the owner**. It replaces roadmap 0012's missing "threat list". Every security decision (ADRs) names the
adversaries it answers. The evidence behind it: diary 2026-11-19-04 to -07; docs/research/security-realism-2026-11-19.md;
docs/research/credentials/; docs/research/threat-model-sota-2026-11-21.md (the state of the art, field by field).

## What Sunset holds (assets)

| # | Asset | Where today | Protected by |
|---|---|---|---|
| D1 | Secrets for the person's accounts: a vault's passwords, codes, files (planned); cookies and session tokens; HTTP auth answers | Vault (planned); WebKit's cookie jar (in the clear, 0600/0700); `CredentialPanel` (not kept) | Vault: its key, locked (ADR-0091). Cookies: the folder's mode only |
| D2 | The storage key and the recovery code | Login Keychain (file-based, ad hoc ACL) | Keychain; FileVault |
| D3 | Behaviour: history, sessions, open tabs, permissions answered, downloads list, recent files, favicons | `state.sqlite`, `session.sealed`, `library.sqlite` | Sealed payloads; times, counts and kinds in the clear until t48 C |
| D4 | The person's documents in Sunset | `Documents/` sealed files | Sealed |
| D5 | What WebKit keeps: network cache (full URLs), website data (IndexedDB, storage, service workers), HSTS, statistics | `~/Library/Caches`, `WebKit`, `HTTPStorages` | 0700 / 0600; cleared at quit for sites not kept (ADR-0081); caches out of backups; cookies and sites' storage sealed while Sunset is closed (2026-11-21) |
| D6 | The terminal's sessions: what programs print, scrollback, the shell's environment | Memory; recording (planned) | The process |
| D7 | The person's input: keystrokes, pastes, clipboard | Memory, the system pasteboard | Clipboard gate; no secure keyboard entry yet |
| D8 | The device's capabilities a page can borrow: camera, microphone, screen, location, notifications | The system (TCC) and Sunset's answers per site | Permission policies (roadmap 0045, ADR-0061, ADR-0082) |
| D9 | Sunset's integrity: its code, its block lists, its settings | The app bundle (Developer ID, notarised, hardened runtime); `Blocking/`; `~/.config/sunset` | macOS; HTTPS for lists |
| D10 | **The engine's freshness** (Sunset WebKit only): its WebKit is at least as new as the last WebKit security advisory | The bundled frameworks, rebuilt by `Scripts/webkit.sh update` | Nothing automatic: macOS updates do not reach it. Advisories come every 5–7 weeks, ≈26 fixes each lately |

## Who attacks (adversaries)

| # | Adversary | Can | Cannot (assumed) |
|---|---|---|---|
| A1 | **A web page** (and its frames, ads, trackers) | Run script in its world; post to Sunset's page-world handlers; show anything; ask for any permission; fingerprint | Reach Sunset's own world (`WKContentWorld`); forge `WKFrameInfo` while WebKit holds (see A10) |
| A2 | **What a terminal shows**: a program, a remote host over SSH, a file `cat`'d | Send any byte sequence; ask replies; write the clipboard (OSC 52) | Read the clipboard; reach the system except by ADR-0010's events |
| A3 | **Another program of the same user** (malware, a curious app, a compromised dependency of another app) | Read every file Sunset owns (0600 is the same user); log keys through event taps (if granted); read memory only with debugging rights (hardened runtime blocks attaching once t49) | Read the Keychain item without a prompt (its ACL); read the data-protection keychain (after t49); read the Secure Enclave key |
| A4 | **Someone with Sunset's files but not the running Mac**: a backup (Time Machine, a cloud backup), a copied `~/Library`, a sync folder's provider, a stolen disk without FileVault | Read what is in the clear; copy, replay, delete, roll back files | Open sealed payloads without the key; open a vault without a factor |
| A5 | **Someone at the unlocked Mac** (borrowed, shoulder-surfing, a screen share) | Use the open app; see the screen; capture it (share, screenshots) | Open a locked vault; see windows excluded from capture |
| A6 | **The network**: a hostile Wi-Fi, an ISP, a proxy | See names (DNS), timing, sizes; tamper with http; block | Read or alter https (WebKit's TLS); alter lists fetched over https |
| A7 | **The sync or backup provider**, honest but curious or malicious | Store, withhold, reorder, roll back, delete Sunset's files | Read or forge sealed records (AEAD, the vault key) |
| A8 | **The supply chain**: dependencies, the build, updates, block list sources | Change what is built or fetched | Dependencies are the owner's own only (§8); no updater exists yet |
| A9 | **An extension** the person installs (t14) | What its permissions give, in WebKit's extension host | What Sunset's own policy refuses (to be written before the first runs) |
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
4. **Sunset ↔ the disk.** Sealed records; the vault sealed by its own key; WebKit's stores outside Sunset's sealing.
5. **Sunset ↔ the network.** WebKit's loads; Sunset's own fetches (lists, icons) through the profile's store.
6. **Sunset ↔ providers** (sync, backup). Sealed bytes only; anti-rollback (below).
7. **Sunset ↔ the system.** Keychain, Secure Enclave, TCC, the pasteboard, notifications, Launch Services (links, downloads).

## Threats, mitigations, gaps

| Threat | Adversary | In place | Gap → where |
|---|---|---|---|
| A page tells Sunset from Safari, tracks it | A1 | ADR-0089 (nothing of Sunset's in the page), ADR-0051/-0074 | Safari's APIs missing (t98), WebAuthn's inconsistent answer (0099 E) |
| A page drives Sunset's handlers (fake clicks, frames, shares) | A1, A10 | Pull, not push; origin from `WKFrameInfo`; bounded (ADR-0067, ADR-0089) | Handlers' fuzzing; a check that a compromised WebContent cannot claim another origin (WebKit's site isolation: to read) |
| A page phishes a fill, reads secrets from hidden fields | A1 | — (no fill yet) | ADR-0094: the person's act, same origin, shown fields, suggestions drawn outside the page |
| A page abuses permissions (camera, notifications, pop-ups, sound) | A1 | Answers per site, asked on gesture, limits (0045, ADR-0061, ADR-0077) | One table of every permission's policy and its test |
| A hostile page exploits WebKit | A1 → A10 | WebKit's sandbox, Apple's updates | Per-navigation hardening (no JIT, `securityRestrictionMode`), HTTPS upgrade (realism study) |
| Escape sequences act outside the screen | A2 | ADR-0010, ADR-0026, ADR-0027: no title, clipboard or font reports, no DECRQSS, bounded replies, REP capped, OSC 7 never looked up | Fuzz targets (0012) with a known-CVE corpus (vt-houdini); C1 controls inside UTF-8 dropped by default since 2026-11-21 (a setting turns them on) |
| A paste runs commands the person did not see | A1/A2 | Bracketed paste | A warning for multi-line or control pastes |
| Keys logged while typing a password in the terminal | A3 | — | Secure keyboard entry |
| Behaviour read from Sunset's files | A3, A4 | Sealed payloads, 0600/0700, `secure_delete`, the WAL truncated | t48 C (times, counts, kinds, row keys) |
| Session tokens and sites' data read from WebKit's folders | A3, A4 | Cleared at quit for sites not kept; caches marked out of backups; cookie jars and sites' storage (IndexedDB, local storage, service workers, statistics, HSTS) sealed at quit, after the network process has put its storage to rest and ended, and opened at launch | A3 while Sunset runs (all in the clear then); a crash leaves them in the clear until the next quit; extensions' storage (`WebExtensions`) not sealed |
| The storage key taken | A3, A4 | Keychain ACL; FileVault | Data-protection keychain and Secure Enclave wrap (the wrap now; the class after t49) |
| A vault opened | A3, A4, A5 | — | ADR-0091 (factors, lock, zeroed buffers, capture exclusion) |
| Clipboard secrets left behind | A3, A5 | Clipboard gate | Concealed type, clearing (0091 D) |
| Screen captured with secrets | A5 | — | `sharingType = .none` for the vault; Sunset's own share skips those windows |
| A sync provider rolls back, withholds, reorders | A7 | — | Per-device logs with sequence numbers; each device remembers the highest seen per device and refuses older; heads sealed and chained (ADR-0095, to add) |
| Backups open to whoever holds them | A4 | Sealed records | A sealed backup of everything (realism study, t48 E) |
| Code injected into Sunset | A3 | — (ad hoc, no hardened runtime) | t49 (hardened runtime, library validation) |
| Lists or updates altered | A6, A8 | Lists over https | A list's size and rule-count bounds; an updater only with signed updates |
| A download runs unchecked | A1 | Quarantine (Gatekeeper) | — |
| An extension oversteps | A9 | ADR-0113: granted at install only, in words (header rewriting named), nothing later, no native messaging; WebKit's permission model | A prompt for later requests (refused today); an audit of each API in WebKit |
| Sunset WebKit runs a WebKit with known bugs | A1 → A10 | `Scripts/webkit.sh update` (< 90 s to apply, ≈61 min to build) | A release on every WebKit advisory; the app saying when its engine is older than the last one |
| Sunset WebKit started with planted loader variables | A3 | Library validation (only Apple's or our team's code); at launch the variables are replaced by its own frameworks and inserted libraries removed, then it restarts | In the first instant, before the restart, frameworks of the launcher's choosing (an older release's WebKit) load: check that the WebKit loaded is the app's own before anything else, or link the bundled frameworks directly |
| An extension's fill menu clicked through an invisible overlay (DOM-based clickjacking) | A1 | Sunset's own fill UI is outside the page (ADR-0094) | Extensions the person installs are as exposed as in other browsers; Sunset's fill: exact origin by default, subdomains on the person's choice |
| Data lost by Sunset itself (safety) | — | Atomic writes, unreadable rows never overwritten, unsaved edits kept (ADR-0038) | A vault's factors all lost → the recovery code; backups tested by restoring |

## How it is kept

- Every new ADR touching data or untrusted input names its rows here, and adds rows when it creates a surface.
- A row's gap closes with a red test first (white paper §9).
- Reviewed when a stage of docs/design/0007 ends.
