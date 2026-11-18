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
| B | The spike: WebKit from the tip of main built on this Mac, bundled, loaded by a signed Sunset; its time, size, and what is lost (DRM especially, as R5 asked) | t28 | not-started |
| C | The two builds: one target set, the engine chosen at build time; the system one stays the default and the light one | t28 | not-started |
| D | Our patches on the own engine (a resolver of our choosing first, for 0046 A), kept as a series rebased on WebKit's main, on a cadence | t28 | not-started |

The owner, later the same day: "consider webkit as a built component we could download at runtime and decide to have the
user download it to make that happen"; "this computer can completely build webkit … patching webkit is also possible and
building on top of it is something some projects are already doing"; "we can do that later".

| E | The own engine as a component downloaded at run time, at the person's choice: one Sunset, the system's WebKit until the person fetches ours; where it is kept, how it is checked (signature), updated, and given up | t28 | not-started |

The owner's directive (ADR-0078): our own WebKit only when shown more performant, safer, more efficient and more reliable;
its form decided after the spike reassesses reliability, safety, convenience and complexity.

Not done: nothing built of WebKit; the cost of keeping a fork current (security fixes between our builds) is R5's first
risk and is the owner's to weigh after B.
