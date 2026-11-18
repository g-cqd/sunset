---
status: in-progress
blocked-by: nothing
date: 2026-11-18
---

# 0045 — The owner's list of 2026-11-18

His words, kept: "Switching to an already loaded tabs does not always keep its exact state (scrolled state in all
aspects)"; "No notifications at all are requested even though some tabs might be emitting some"; "Sometimes, some tabs
fail to load or the load indicator is not accurate or updated when the tab finishes loading"; "setting the sidebar to
floating when on a webpage creates an odd blank space at the top of the content pane"; "the space and profile switching
and the alpha masking should be better animated … if a space has pinned, favorites and tabs and another one only tabs,
the tabs get aligned together whereas they should be on the top of the sidebar in the space that only has one tab";
and "further and deepen the work on the chrome (or other impersonation) as for example the sites like
app.site.example or develop.site.example or staging.site.example are not loading properly". Commits
local only (nothing can be pushed from this machine), rebased on the remote as it moves; rebuilt and installed at the end.

| Step | What | Task | Status |
|---|---|---|---|
| A | A loaded tab shown again keeps its exact state, scroll included | t2 | not-started |
| B | A page's notifications reach the system: Sunset asks the system to notify | t3 | not-started |
| C | A tab that fails to load, or whose load indicator is wrong or not updated when it ends | t4 | not-started |
| D | The floating sidebar on a page leaves no blank space at the top of the content | t5 | not-started |
| E | Space and profile switches, the alpha mask, animated smoothly; a Space with only tabs has them at the top | t6 | not-started |
| F | Appearing as Chrome, deeper; the site.example sites load | t7 | done (below) |
| G | Rebuilt and installed (`Scripts/install-app.sh`) | t8 | not-started |

## F as built (ADR-0074; diary 2026-11-18-03)

- **Why the sites did not load**: they send a browser they do not support (Safari, so Sunset by default) to
  `/public/incompatible?skipIncompatible=true` with `location.replace`, and that page never sends it back. Shown Chrome
  from the site's panel afterwards, Sunset loaded *that* page again and stayed there. Now the address the person asked
  for is loaded again when a script of the same site has sent the page away since (`AskedAddress`). Seen on the real
  site from Sunset's own page: develop.site.example, Safari → the incompatible page → "Chrome" → the login page.
- **Deeper**: what a page's scripts read compared with Chrome Canary 160 on this Mac. Now as Chrome's: a
  `NavigatorUAData` (prototype, `toString` tag, constructor), Chromium's brands and their order for the version,
  `getHighEntropyValues` (sorted, refusing what is not a list), `deviceMemory`, `window.chrome` (`app`, `csi`,
  `loadTimes`, no `runtime`), every function Sunset sets reading `[native code]`, native functions written on one line;
  gone shown Chrome, Edge or Firefox: `navigator.standalone`, `GestureEvent`, `WebKitPoint`, the force-click handlers.

Not done in F, said plainly:

- `window.webkit` stays (an app's web view's; it cannot be deleted): a script can tell a web view by it.
- The engine is WebKit: 65 of the 144 values read still differ from Chrome's (APIs Chrome has and WebKit has not,
  error messages, stack format, codecs, WebGL; 4 more are only the oracle's version and its "HeadlessChrome"), and
  nothing reaches workers. No `Sec-CH-UA` headers. Full versions
  are `.0.0.0`. `deviceMemory` above 16 GB is not probed against Chrome.
- A tab restored at the site's "unsupported" page has no address asked for: it is loaded again where it is.
- Nothing past the site login page was tried (no account); W-b (a shipped list of site rules) is still the
  owner's deferral (ADR-0051), so each of these sites needs "Appears as Chrome" once.
