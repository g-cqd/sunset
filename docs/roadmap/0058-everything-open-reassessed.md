---
status: in-progress
blocked-by: nothing
date: 2026-11-18
---

# 0058 — Everything open, reassessed (the owner, 2026-11-18, late evening)

Every roadmap entry not done (43 of 58), every open task (11) and every note (n1–n49, all now fulfilled but n46) read
again. Supersedes the staging of roadmap 0056. Stages in order; within a stage, the order of the rows.

## Stage 1 — open from today, small (each under half a day)

| # | What | From |
|---|---|---|
| 1.1 | The crash while a menu was open: watch for it again on the new build; if it recurs, a symbolicated report | n46, t76 |
| 1.2 | Share a tab: a page never loaded is listed by its address (its saved title instead); a shared terminal or document has no mark on its tab | 0057 — done (diary 2026-11-19-04) |
| 1.3 | Profiles: the Websites page's list of answers per profile; elements hidden per profile (one compiled list per profile) | 0050 E — done |
| 1.4 | The floating bar's native-toolbar form (when kept shown) | 0055 C — done, not seen |
| 1.5 | One flaky test (`WebNotificationsTests`, close reaching Sunset, timing) | diary — done |
| 1.6 | The cookie jar is rewritten 0644 by WebKit at quit (kept only by its folder's 0700): set again after WebKit has written | 0051 G — done, not checked in Sunset |

## Stage 2 — security and storage (0051), with the measurements asked

| # | What | Task |
|---|---|---|
| 2.1 | C: times, counts and kinds into the sealed payload; row keys by HMAC with a key of their own; a migration that reseals | t48 |
| 2.2 | D: what the recovery code is; Argon2id (our own, an Aemi package) if it can be typed | t48 |
| 2.3 | E: exports sealed by default | t48 |
| 2.4 | I: WebKit's stores sealed (an encrypted image opened with the Keychain key), performance, stress and benchmark runs against the stores in the clear (release, percentiles) before a decision | t51, t59 |
| 2.5 | F: Developer ID, hardened runtime, library validation, Secure Enclave wrapping | t49 — **blocked on the owner's certificate** |

## Stage 3 — settings and help, finished

| # | What | From |
|---|---|---|
| 3.1 | Every page's wording reviewed, page by page (the last of 0047 G, 0052 E) | t24 |
| 3.2 | The focused tab's accent from the site's icon or theme colour (0047 H) | t25 |
| 3.3 | Help for the topics without it; "Open in Help" from a popover (0041) | 0041 |
| 3.4 | Settings' and Help's pages under tests (the app target has none) | 0032 |

## Stage 4 — what was never seen, and open bugs not reproduced

| # | What | From |
|---|---|---|
| 4.1 | The owner's reports not reproduced: the Library's empty document list, a split page "not a web tab"; the cup's slash (a design question) | 0042 A, B, G |
| 4.2 | Seen on screen, what only tests checked: drags, hover reveals, notifications in Notification Centre, the light scheme, the left sidebar, microphone and camera on a tab, a page in a profile searching with its own engine | 0042 E, F; today's |
| 4.3 | Measured (release, percentiles): tab and Space switches, opening a window, the sidebar's frames | 0049 row 8 |

## Stage 5 — the decided roadmaps not started (refinement done)

| # | What | Roadmap |
|---|---|---|
| 5.1 | Restoring the running state (R7) | 0024 |
| 5.2 | The terminal's open ends (R9): small builds, measurements, then designs | 0026 |
| 5.3 | Commands, keys, the command bar's table, App Intents (R11) | 0027 |
| 5.4 | The shell's polish, notes n49–n67 of before | 0028 |
| 5.5 | Spaces and profiles' leftovers: history per profile, a cue for a tab another window draws or a stopped one | 0021 |
| 5.6 | Markdown M-g to M-i: scrolling together, in-page links, pictures, `markdown.*` settings, rows by block | 0023 |
| 5.7 | The Library: keys per section, one way to downloads, files opened listed | 0031 |
| 5.8 | `scopes.tabs`: a window's own tabs in a Space | 0044 D |

## Stage 6 — the web's depth (later by the owner's order)

| # | What | Roadmap / task |
|---|---|---|
| 6.1 | WebKit's private network interfaces (resolver, proxy per store already probed) | 0048 A, t27 |
| 6.2 | DNS over HTTPS/TLS/QUIC | 0046 A, t13 |
| 6.3 | Impersonation beyond identity (APIs, error messages, codecs, workers, client hints) | 0046 D, t15, 0045 F, 0022 |
| 6.4 | Extensions, the proxy APIs first | 0046 B, C, t14 |
| 6.5 | Notifications without a click asked (Chrome) and service-worker notifications as settings (ADR-0077: decided) | 0046 S1, S2 |
| 6.6 | The own WebKit: spike, two builds, our patch series, run-time download (ADR-0078: only if shown better) | 0048 B–E, t28 |

## Stage 7 — the terminal's foundations (long running, partly done)

VT parser and screen leftovers (0003), PTY host (0004), oracles and fuzzing (0005), colour pipeline (0006), font stack
(0007), renderer (0008), kitty graphics (0010), modern protocols (0011), the security model's spec and fuzz targets (0012),
the competitor baseline (0014), kernels and promotions to Aemi (0001, 0015), remote control (0016), Linux (0013), the shell as
a library of its own (0025 H-3).

Not done: everything above; this entry is the order, kept current as rows finish.
