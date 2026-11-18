---
status: accepted
date: 2026-11-18
---

# 0073 — A proxy for the pages is WebKit's own, on every store

The owner's note n75: a proxy set in Sunset, for the whole app first, later per profile or per Space. First form,
decided while the owner asked not to be asked (2026-11-18).

## Decision

1. **`web.proxy`**: `http://host:port` (CONNECT) or `socks5://host:port`; empty for none. Anything else is said and left
   out (an https proxy too: not a kind WebKit is given here).
2. **Every store of pages has it** (`WKWebsiteDataStore.proxyConfigurations`, macOS 14): the first profile's, every
   other profile's, every private window's; given when a page is made, and to the stores that exist when it changes.
3. **Probed, not assumed**: a test runs a proxy on this Mac that answers every request itself; a page of a name that
   does not exist (`.invalid`) loads through it, by a CONNECT to the name then the request in the tunnel.

## Not done

- Sunset's own requests (a tab's icon, suggestions, the blocking lists, `WebFetch`) do not go through it: Settings say so.
- Credentials for a proxy; a list of hosts that go direct; a proxy per profile or per Space (the owner's "later").
- DNS over HTTPS, TLS or QUIC (n75's third wish): not started.
