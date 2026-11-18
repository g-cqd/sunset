# What WebKit lets an app do with pages not on screen (task t134, 2026-11-18)

The study R4 asked for before S-f: WebKit's official controls over sleeping pages, and what a page restored can get back.
Tags: **[docs]** read in Apple's documentation (apple-docs, 2026-11-18); **[probe]** run here,
`Scripts/probes/webkit-hidden-page-timers.swift`, macOS 26 on this Mac; **[unverified]** not checked.

## The controls

| Control | What it says | Status |
| --- | --- | --- |
| `WKPreferences.inactiveSchedulingPolicy` (macOS 14+): `.suspend`, `.throttle`, `.none` | "how a web view that's not in a window handles tasks": suspend fully, limit, or nothing | [docs]. Default `.suspend` (raw 0) [probe] |
| A view out of its window | — | [probe] a page's 50 ms `setInterval` runs ~19 times a second in a window, **about once a second out of it, with every policy** (22 ticks in 20 s for `.suspend`, `.throttle`, `.none` alike), and at full rate at once when put back. The policy made no difference that a timer shows; what it changes (the process's suspension) was not seen |
| The policy on a live view | `view.configuration.preferences` is one object; setting it changes what the view reports | [probe]; whether WebKit applies it to a page already made is [unverified] |
| `WKWebView.interactionState` (macOS 12+) | the back-forward list and the place in it, as data to give a new view | [docs]; Sunset uses it already to restore a page (its `history`) |
| `WKWebView.fetchData(of: .sessionStorage)` / `restoreData(_:)` (macOS 26) | a page's session storage, taken and given back | [docs]; not used yet; would keep a page's `sessionStorage` across an unload or a restart (R7's question) |
| `pauseAllMediaPlayback`, `setAllMediaPlaybackSuspended`, `cameraCaptureState`, `microphoneCaptureState` | media and capture | [docs]; Sunset watches sound and capture already |
| Memory pressure | no WebKit control. macOS's own level: `sysctl kern.memorystatus_vm_pressure_level` (1 normal, 2 warning, 4 critical) | [probe] reads 1 here. `DispatchSource.makeMemoryPressureSource` is the usual way, and is dispatch (ADR-0033: none) |

Upstream WebKit has more (back-forward cache, process suspension of background tabs in Safari) behind SPI; not used
(ADR-0002: no private API outside a seam, and none is needed for what R4 asks).

## What this means for S-f

1. **Sleeping is WebKit's already**: a page that is not on screen is out of its window, and its timers slow to about one a
   second at once. A "sleep after 15 minutes" setting would have nothing of its own to do; the moon cue would mark a
   state the page is in as soon as it is hidden.
2. **Unloading is the app's**: let go of the view, keep `interactionState`, the address and the picture; make it again
   when shown. That is what frees the memory.
3. **Memory pressure** can be read without dispatch, by polling the level (cheap: one sysctl a minute).
