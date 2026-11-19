---
status: accepted
date: 2026-11-19
---

# 0102 — HTTPS first, the hardened mode and Global Privacy Control are settings

## Context

WebKit offers each navigation protections Sunset never asked for (diary 2026-11-19-07; task t115):
- an HTTPS upgrade policy (macOS 15.2);
- the hardened mode (macOS 26.4: no JIT, more memory tagging);
- Global Privacy Control (macOS 27).

Measured (diary 2026-11-19-11):
- HTTPS first costs nothing on localhost, and moved `http://example.com` to https, faster;
- the hardened mode makes a numeric script 7× slower and a string-and-object one 2.4× slower.

## Decision

Under Privacy and security › Protection on the web, each page's navigations carry:
- `web.httpsUpgrade`: try HTTPS first, then HTTP (the default), ask before HTTP, HTTPS only, or as the address says;
- `web.hardening`: off (the default), or without JIT;
- `web.globalPrivacyControl`: in private windows (the default), always, or never.

The settings apply to pages opened after a change.

## Consequences

- An http page reached by the fallback keeps showing Not Secure (`isNotSecure` reads the address it ended on).
- Per-site choices (a site always hardened, a site always as asked) are not done.
- Lockdown per navigation is not offered: macOS's own Lockdown Mode applies it by itself.
