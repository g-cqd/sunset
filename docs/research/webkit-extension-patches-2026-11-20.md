# WebKit's Web Extensions: what to patch for Sunset (2026-11-20)

Claims until a patched WebKit is built and probed (roadmap 0048 B, D). Sources: WebKit `main` on GitHub, read
2026-11-20; behaviour probed on the system's WebKit (macOS 27.2.1), diary 2026-11-20-15 and -16.

## Where each defect lives

| Id | Defect | Where in WebKit | The patch | Size |
|---|---|---|---|---|
| W1 | A method called apart from its namespace gives `undefined` | `Source/WebKit/WebProcess/Extensions/Bindings/Scripts/CodeGeneratorExtensions.pm`: each generated function finds its object from `thisObject` (`to<Impl>(context, thisObject)`), and returns undefined when `this` is not a wrapper | Fall back to the object the function was read from (kept on the function when the getter hands it out), as Firefox and Chrome do | small, in the generator: every API at once |
| W2 | `i18n.getMessage("")` throws | `Source/WebKit/WebProcess/Extensions/Interfaces/WebExtensionAPILocalization.idl`: `getMessage([CannotBeEmpty] DOMString name, …)` | Drop `[CannotBeEmpty]`; `localizedStringForKey` of an empty key gives `""` (to check) | one line |
| W3 | What a script adds to a namespace object is lost | `Bindings/JSWebExtensionWrapper.cpp`: wrappers cached in a `JSWeakObjectMap`; collected, made again bare | Keep a child namespace's wrapper alive as long as its parent's (the parent holds it), as the DOM's opaque roots do | small to medium |
| W4 | `webNavigation.onCreatedNavigationTarget` missing (Firefox and Chrome have it; uBO blocks pop-ups with it) | `Interfaces/WebExtensionAPIWebNavigation.idl` (five events), the UI process's navigation hooks | A new event, fired when a page opens a window or tab (the UI delegate's `createWebView` path) with source tab and frame | medium |
| W5 | `requestIdleCallback` off in extension pages | a feature flag, off in an app's views | none: Sunset turns it on (`SafariParity`) | — |
| W6 | Blocking `webRequest` (MV2): `{cancel: true}` ignored, uBlock Origin filters nothing | `API/Cocoa/WebExtensionAPIWebRequestEventCocoa.mm`: `addListener` keeps only `requestBody`, `requestHeaders`, `responseHeaders` of `extraInfo` (`"blocking"` dropped); `invokeListenersWithArgument` calls each listener and ignores what it returns; the events are sent after the fact from the UI process | A load held until the extension's background page answers: a synchronous round trip network process → UI process → extension's process, on every request it filters; cancel and redirect first | large: the deepest change, the one with a cost on every load |

## Done (diary 2026-11-20-17, -18)

- W2: the IDL line, as planned.
- W3: as planned, through the generated getter (`JSObjectSetPrivateProperty` on the object read from).
- W1: first by binding every function of every new wrapper (v1: +6 % on new frames, +2 MB, diary -20); now by the sole
  object of a class in its context, looked up only on a detached call (v2: no cost seen against the base).
- W3: pinned only when a wrapper is made (v2), not at every read.
- W6a: cancel, held in the network process only for pages whose extensions have blocking listeners (about 0.1 ms a request
  there).
- W7 found on the way: `ws://` and `wss://` match patterns refused by `webRequest.addListener`.

## Probed on the system's WebKit

- W6: a minimal MV2 extension with a blocking `onBeforeRequest` listener: the listener is added without an error and sees
  some requests (the page, scripts' own requests), not the four scripts the page loads; `{cancel: true}` blocks nothing.
  uBlock Origin itself: AdSense, Analytics and DoubleClick scripts all load, its cosmetic filters not applied.
- uBlock Origin's Firefox build also calls Firefox-only APIs: `contentScripts.register` (Firefox's own, not in WebExtensions'
  common set), `wrappedJSObject` (Firefox's content script view), `runtime.onUpdateAvailable` (missing in WebKit). These are
  uBO's Firefox choices: a WebKit patched for W1–W6 still would not run uBO's Firefox build whole.
- uBlock Origin Lite (MV3, `declarativeNetRequest`, which WebKit turns into content rule lists) filters without any patch.

## What this says

- W1–W3 are small, generic, and fix every extension at once; W2 is one line. Worth sending upstream as well as keeping.
- W6 is what an MV2 blocker needs and what Apple left out on purpose (a load held on an extension's script). As a patch of
  ours it is large and costs on every load; the measure of that cost (release, percentiles, against Safari's content
  blocking) decides it.
- Until our own WebKit exists, `ExtensionPageShim` covers W1–W4 in script and uBO Lite is the blocker that works.
