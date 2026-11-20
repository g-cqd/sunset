---
status: not-started
blocked-by: nothing
date: 2026-11-18
---

# 0048 — Two builds of Sunset: on the system's WebKit, and on a WebKit of our own we can patch

The owner, 2026-11-18: "regarding proxy topics, it would be nice and interesting to investigate private apis through
webkit or see whether we can patch webkit itself, an ulterior roadmap item we had was to create release variants of
sunset, one with native webkit, thus making sunset very lightweight, and one bundling and compiling through
nightly/upstream webkit, that we could then patch ourselves for our specific needs". This carries roadmap 0022 E (the own
engine, t119) on, with patching added.

| Step | What | Task | Status |
|---|---|---|---|
| A | WebKit's private interfaces for the network, through the `SunsetPrivate` seam | t27 | first probe done: a PAC script and fixed proxies work in a store made from the private configuration (docs/research/network-dns-proxy-extensions-2026-11-18.md); not wired |
| B | The spike: WebKit from the tip of main built on this Mac, bundled, loaded by a signed Sunset; its time, size, and what is lost (DRM especially, as R5 asked) | t28 | in-progress: WebKit main built here in 1 h (36 GB); an app runs on it; an incremental build after a patch 3 min (diary 2026-11-20-17). Not yet: Sunset itself on it, signed, bundled; DRM |
| C | The two builds: one target set, the engine chosen at build time; the system one stays the default and the light one | t28 | not-started |
| D | Our patches on the own engine, kept as a series rebased on WebKit's main, on a cadence (ADR-0110: `Engine/WebKit/base`, `Engine/WebKit/patches`, `Scripts/webkit.sh`). The owner's order, 2026-11-20: W1–W3, W6, the resolver (0046 A, t13) | t28 | in-progress: W2 (0001), W3 (0002, test 0003) and W1 (0004, test 0005), W7 (0006, 0007), W4's event (0008, 0009) , W6a (0010, 0011) built and checked; W1 and W3 redone after the audit, no cost seen against the base (diaries 2026-11-20-18 to -20). Next: W6b, W6c, the resolver |

The owner, later the same day: "consider webkit as a built component we could download at runtime and decide to have the
user download it to make that happen"; "this computer can completely build webkit … patching webkit is also possible and
building on top of it is something some projects are already doing"; "we can do that later".

| E | The own engine as a component downloaded at run time, at the person's choice: one Sunset, the system's WebKit until the person fetches ours; where it is kept, how it is checked (signature), updated, and given up | t28 | not-started |

The owner's directive (ADR-0078): our own WebKit only when shown more performant, safer, more efficient and more reliable;
its form decided after the spike reassesses reliability, safety, convenience and complexity.

Not done: nothing built of WebKit; the cost of keeping a fork current (security fixes between our builds) is R5's first
risk and is the owner's to weigh after B.

## WebKit patch candidates (step D)

The owner, 2026-11-20: "we might want to keep some of those fixes for the patches on webkit later". Each defect found in
WebKit is listed here with its repro; Sunset's stopgap names it, and goes when our WebKit fixes it.

| Id | Defect (WebKit, Web Extensions) | Firefox / Chrome | Repro | Stopgap |
|---|---|---|---|---|
| W1 | A namespace's method called apart from it (`const f = browser.runtime.getURL; f("")`) gives `undefined` | the URL | `ExtensionHostTests` "a Firefox extension's background page…" (`detached`) | `ExtensionPageShim`: methods bound |
| W2 | `i18n.getMessage("")` throws | `""` | same test (`empty`) | `ExtensionPageShim`: wrapped |
| W3 | Properties added to a namespace object are lost when its wrapper is collected and made again | kept | diary 2026-11-20-15 | `ExtensionPageShim`: wrappers kept alive |
| W4 | `webNavigation.onCreatedNavigationTarget`, `webRequest.handlerBehaviorChanged` missing | present | same test (`event`, `changed`) | `ExtensionPageShim`: inert stand-ins (no target navigation events, so uBO cannot block pop-ups that way) |
| W5 | `requestIdleCallback` off in an app's views (extension pages included) | on | same test (`idle`) | `SafariParity` on the extension pages' configuration |
| W7 | `webRequest.addListener` refuses `ws://` and `wss://` match patterns | accepted | uBO on our WebKit (diary 2026-11-20-18) | none |
| W6 | Blocking `webRequest` (MV2) not supported: `{cancel: true}` ignored, uBlock Origin's network filtering does nothing | supported | probed: diary 2026-11-20-16 | none (uBO Lite filters through `declarativeNetRequest`) |

| W8 | `runtime.onUpdateAvailable` missing | present | uBO on our WebKit (diary 2026-11-20-19) | `ExtensionPageShim`: an inert event (diary 2026-11-20-21) |
| W9 | A custom scheme (`abp:*`) refused in `menus.create`'s `targetUrlPatterns` | accepted | the same | none |
| W10 | `webRequest` events missing for loads answered from the HTTP cache | fired | diary 2026-11-20-21 | none (the blocking path is held before the cache: 0012) |
| W6d | An extension's redirect to its own file or to `data:` (a surrogate) fails as a block | internal redirect, loads | the same | none |

Patched in our WebKit (`Engine/WebKit/patches`): W2 (0001), W3 (0002, its test 0003), W1 (0004, its test 0005), W7 (0006,
0007), W4's event (0008, 0009; `handlerBehaviorChanged` not yet, W4b), W6's cancel (0010, 0011, before the cache 0012) and redirect (0013, 0014; to http(s) only, W6d), headers not yet;
uBlock Origin filters on our WebKit with Sunset's shim; W1 and W3 redone after the owner's audit, measured against the base (diary 2026-11-20-20); the
stopgaps in `ExtensionPageShim` stay for the system's WebKit.

Where each lives in WebKit and the patch for it: `docs/research/webkit-extension-patches-2026-11-20.md`. W1–W3 are small and
generic (every extension at once), W2 one line; W6 is large and costs on every load.
