---
status: accepted
date: 2026-11-18
---

# 0079 — The pages' network: WebKit's private proxy configuration first, a gateway in Sunset for DNS after; app-wide, a profile may differ

The owner, 2026-11-18: "Both, private first"; "network aspects should have a way to be set for the whole app".

## Decision

1. Proxies (fixed servers, a PAC script; what an extension's `chrome.proxy` sets) go through WebKit's private store
   configuration (`_WKWebsiteDataStoreConfiguration.proxyConfiguration`, probed: a PAC script routes per host), behind the
   `SunsetPrivate` seam, with a test that fails when a macOS update takes it away.
2. Encrypted DNS (over HTTPS, TLS, QUIC) comes after, through a gateway inside Sunset that resolves names itself (the
   system's switch does not let Sunset choose the resolver: probed), its cost measured before it is on by default.
3. Network settings are the app's, for every window and profile; a profile may set its own, which then wins for its pages.

## Consequences

A store is made per proxy setting (it cannot be changed once made: probed); changing a proxy reloads the pages it carries.
