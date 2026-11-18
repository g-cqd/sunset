---
status: accepted
date: 2026-11-18
---

# 0074 — Appearing as another browser reads as that browser to scripts, checked against the browser itself

Supersedes nothing; deepens ADR-0052 (the second rung) at the owner's asking (roadmap 0045 F, 2026-11-18: "further and
deepen the work on the chrome (or other impersonation)").

## Context

ADR-0052 set what a detection script reads first (`navigator.vendor`, `navigator.userAgentData`, `window.chrome`).
Compared with Chrome Canary 160 on the same Mac (diary 2026-11-18-03), what it set did not read as Chrome's: a plain
object for `userAgentData`, getters whose text was their source, a GREASE brand Chrome would not send for the version,
`chrome.runtime` that Chrome without extensions has not, and Safari's own names left in place. The owner's sites
(site.example) were not stopped by any of that but by a page that never sends a browser back (below).

## Decision

1. **Chrome is the oracle**: values are those Chrome gives on this Mac, read from Chrome itself, quoted as Chrome's;
   the brand list follows Chromium's own algorithm (`ChromiumBrands`, from `user_agent_utils.cc`), checked against 160.
2. **Identity, not features**: only what a script reads to tell a browser is set. An API WebKit lacks is never faked
   (a page would call it), and media, codecs and error messages are left as WebKit's.
3. **What Sunset sets reads as native**: `Function.prototype.toString` gives `[native code]` for Sunset's own functions,
   and, shown Chrome or Edge, writes native functions on one line as V8 does. Shown Firefox, WebKit's form is Firefox's.
4. **Safari's own names go** when another browser is shown: `navigator.standalone`, `GestureEvent`, `WebKitPoint`, the
   force-click handlers. `window.webkit` stays: it cannot be deleted, and Sunset's notifications need it.
5. **A browser change loads what the person asked for** when a script of the same site has sent the page away since
   (`AskedAddress`); a page moved by `pushState` is loaded again where it is.

## Consequences

A detection script that reads further (an API's presence, error text, workers, WebGL, the TLS handshake) still tells
WebKit. `Function.prototype.toString` is Sunset's on pages shown another browser; a page that compares it with itself
across frames still sees one function per frame, as in Chrome.
