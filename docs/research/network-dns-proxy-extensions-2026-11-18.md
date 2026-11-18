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

## WebKit's private interfaces for the network (probed 2026-11-18, the owner: "investigate private apis through webkit")

Read from the Objective-C runtime of macOS 27.2.1's WebKit (names only; what they do is probed below or is a claim):

- `_WKWebsiteDataStoreConfiguration`: `proxyConfiguration` (a CFNetwork proxy dictionary), `httpProxy`, `httpsProxy`,
  `requiresSecureHTTPSProxyConnection`, `preventsSystemHTTPProxyAuthentication`, `allowsServerPreconnect`,
  `alternativeServicesStorageDirectory` (HTTP/3's Alt-Svc), `legacyTLSEnabled`.
- `WKWebsiteDataStore`: `_setProxyConfiguration:`, `_setAllowsTLSFallback:`, `_allowTLSCertificateChain:forHost:`,
  `_terminateNetworkProcess`.
- `WKPreferences`: `_setDNSPrefetchingEnabled:`. `WKWebViewConfiguration`: `_setAllowedNetworkHosts:`, `_setLoadsFromNetwork:`.
- Nothing names a resolver: no DNS over HTTPS, TLS or QUIC of WebKit's own.

| Claim | Probe | Verdict |
|---|---|---|
| A proxy auto-configuration script (PAC) given in the private configuration routes a page's requests per host | `PrivateProxyProbeTests` (`SUNSET_PRIVATE_PROBE`): `ProxyAutoConfigJavaScript` with `FindProxyForURL` sending `*.by-script.invalid` to a proxy on this Mac and the rest direct; a store made by `-[WKWebsiteDataStore _initWithConfiguration:]` | Yes: `page.by-script.invalid` loaded through the proxy (title "proxied"), `elsewhere.invalid` did not reach it. A fixed HTTP proxy in the same dictionary sent both |
| The same dictionary set on a store after it is made (`_setProxyConfiguration:`) | Same probe | No: nothing reached the proxy, either form |

So `chrome.proxy` with `pac_script` and `fixed_servers` could map onto WebKit's own networking (a store per proxy
setting, made with it), with no gateway: by private interface, which a macOS update can take away (ADR on the
`SunsetPrivate` seam's rule). Encrypted DNS still needs Sunset's own resolver (above).

## The own engine (roadmap 0022 E, t119; the owner again 2026-11-18)

Not probed today. Claims to probe in the spike: a WebKit built from the tip of main (`Tools/Scripts/build-webkit`)
bundled in Sunset with its XPC services (WebContent, Networking, GPU) and their sandbox profiles, loaded by a signed app;
what is lost (FairPlay video, passkeys, Apple Pay, the system's content filters: R5 suspected, not verified); the build's
time and size on this Mac (8 cores, 95 GB free); and that Playwright ships patched WebKit builds for macOS (their claim).
