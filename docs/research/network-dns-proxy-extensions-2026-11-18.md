# Encrypted name resolution, proxies and extensions for pages (roadmap 0046), 2026-11-18

Claims until probed; other projects' statements are theirs.

## Probed here

| Claim | Probe | Verdict |
|---|---|---|
| A proxy set on a page's store sees the names the page asks for, not addresses | Upstream's `WebProxyTests` (ADR-0073): a page of `through-the-proxy.invalid` loads through a proxy on this Mac | Yes: `CONNECT through-the-proxy.invalid:80`, then the request in the tunnel. A proxy inside Sunset could resolve every name the pages ask for |
| Network.framework's privacy context makes a connection resolve over the resolver Sunset names | `Scripts/probes/network-encrypted-dns.swift`: `requireEncryptedNameResolution(true, fallbackResolver:)` with Cloudflare over HTTPS, over TLS, and with a resolver that cannot be reached; names never asked before (`p<random>.github.io`) | Refuted: the unreachable resolver resolved too. The resolver given is a fallback; the system's answered. Sunset cannot choose the resolver this way: it has to resolve names itself |
| WebKit's extension engine offers `proxy` | `WKWebExtension.Permission` (Apple's documentation, macOS 15.4): 16 permissions (activeTab, alarms, clipboardWrite, contextMenus, cookies, declarativeNetRequest ×3, menus, nativeMessaging, scripting, storage, tabs, unlimitedStorage, webNavigation, webRequest) | No `proxy`, no `dns`: a proxy extension needs Sunset to provide `chrome.proxy` |
| A store can be given what a proxy extension asks for | `Network.ProxyConfiguration` (documentation): HTTP CONNECT with TLS options, SOCKS5, relay hops, Oblivious HTTP, match and excluded domains, credentials | Fixed servers and bypass lists map onto it; a PAC script does not (nothing evaluates one) |

## Read, not probed

- **g-cqd/HTTP** (README, 2026-11-18): a server library: sans-I/O HTTP/1.1, HTTP/2 (HPACK) and HTTP/3 (QPACK) engines over
  Network.framework, QUIC included; no DNS, no client. What DoH needs of HTTP, URLSession already does; what DoQ
  (RFC 9250) needs is QUIC streams, which HTTP drives through Network.framework: its transport is the part to read.
- **driceroland/Search** (README): runs Chrome extensions on `WKWebExtension` and, by its account, "where Chrome has APIs
  WebKit doesn't … fills them in itself": a script added at install to the extension's worker, pages and content scripts
  defines the missing APIs as calls answered natively, and mends where WebKit differs. MIT. Its code is the place to read
  for 0046 B and C, and for D (filling what a page shown Chrome misses).

## A proposition for the owner (not decided)

One gateway inside Sunset that every page goes through (the stores' proxy, as `web.proxy` is set today):

1. Names resolved by Sunset: DNS over HTTPS (RFC 8484, URLSession), over TLS (RFC 7858, `NWConnection` on 853), over QUIC
   (RFC 9250, `NWProtocolQUIC`); a cache by TTL; the DNS message codec and the three clients generic, so an Aemi package
   (or Aemi), as the owner said.
2. Then direct, or through the person's proxy (`web.proxy`), or as an extension's `chrome.proxy` says (fixed servers,
   bypass list; a PAC script evaluated by JavaScriptCore), per profile later.
3. Costs to measure before it is adopted: a second hop on every connection (latency at the first byte, CPU, memory), and
   what is lost (WebKit's own happy eyeballs and HTTP/3: a CONNECT tunnel carries TCP; whether pages keep QUIC is to probe).
