---
status: accepted
date: 2026-11-17
---

# 0063 — Sites' icons are kept on disk, by host, until the server says they expire

The owner, 2026-11-17 (roadmap 0035 H): "Have a way to cache favicons when tabs are unloaded". His answers: on disk; "we
might want to respect cache expiration and ensure that we reload them accordingly. also website might update them
interactively and we want to catch that as well and that should discard a cached favicon. this handling should happen in
the background as well when a tab is set to show an icon, and we need to make sure that the favicon does not replace the
icon then when it is set, but user can decide to go back to the favicon".

## Decision

1. **`FaviconStore`**: one sealed record per host in the state database (`favicons`), the icon made a PNG of 64 px at
   most, its source address and when it expires; read back at launch. Before, icons were kept in memory for the run.
2. **Expiry is the server's**: `Cache-Control: max-age`, else `Expires`, else a week; no-store and no-cache expire at
   once; never more than 30 days. An expired icon still shows; the next load of a page of the site fetches it again (as
   before: without cookies, as the browser the site is shown). A site with no icon is not asked again during the run.
3. **An icon the page changes while it runs replaces the one kept** (`IconWatch`, a script in Sunset's own world watching
   the page's `<link rel="icon">`; at most once a second).
4. **A tab not running shows its site's kept icon** (`EnvironmentValues.savedPicture`, given by the app while
   `web.tabIcon` is favicon); a private page's never.
5. **A picture the person gave the tab wins** over the site's icon, which is still fetched and kept; "No Icon" in the
   icon picker goes back to it.
6. Clearing the history (and `web.clearHistoryOnQuit`) forgets them all.

## Not done

- Not seen on screen.
- The icon picker's "No Icon" is not renamed for a page (it means "the site's icon" there).
