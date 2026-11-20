---
status: in-progress
blocked-by: nothing
date: 2026-11-20
---

# 0109 — Extensions (ADR-0109; task t14)

The owner, 2026-11-20: Chrome's and Firefox's extensions now, without `chrome.proxy`; installed from files and from the stores'
own pages; granted at install; per profile; off in private windows by default; both blockers apply; actions in the sidebar's
header row.

| Step | What | Status |
|---|---|---|
| A | Packages: `.crx` (CRX3's header off), `.xpi` and `.zip` as WebKit's zip, unpacked folders; each install a copy in the profile's folder | done (diary 2026-11-20-13) |
| B | The engine wired: a persistent controller per profile; WebContent as `WKWebExtensionTab`, windows as `WKWebExtensionWindow`, opened, closed, activated | in-progress: controllers per profile, pages as tabs (opened, closed), private by each context's access: done; windows and activation not |
| C | Install: the prompt listing what it asks, granted at install; Settings ▸ Extensions (on, off, private windows, remove, what it may do) | done; Settings and the menu item seen, the prompt not (diary 2026-11-20-13) |
| D | Actions: icons, badges and popups in the sidebar's header row between the sidebar button and the lights | done, seen (diary 2026-11-20-13) |
| E | The stores' pages: "Add to Chrome" and "Add to Firefox" install in Sunset | done: Add to Sunset in place of the store's button, packages fetched from the stores, `.crx`/`.xpi` links installed; seen on the Chrome Web Store; Firefox Add-ons not seen |
| F | Private windows per extension; Sunset's own pages and views never reached | done (tests) |

Not done: B's windows and activation; the install prompt seen answered by a person (an alert here was clicked by something else, diary 2026-11-20-13); Firefox Add-ons seen.
