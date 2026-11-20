---
status: accepted
date: 2026-11-20
---

# 0109 — Extensions run on WebKit's engine, granted by the person, off in private windows

## Context

The owner (2026-11-20) asked for extensions now, without the proxy API (t14; `chrome.proxy` waits on the network work, t13).
WebKit's `WKWebExtension` (macOS 15.4) runs Chrome's and Firefox's Manifest V3 extensions: it enforces their permissions;
the app grants them and describes its tabs and windows (probed: diary 2026-11-20-13). An extension is code from someone else,
running in every page it is granted: white paper §9 wants a policy and a test for each thing it can ask.

## Decision (the owner accepted it, 2026-11-20, with the changes below)

1. **Engine**: WebKit's (`WKWebExtensionController`), one persistent controller per profile: an extension's storage and
   grants are the profile's.
2. **Sources**: an unpacked folder, a `.zip`, Chrome Web Store and Firefox Add-ons packages (`.crx`, `.xpi`), and **installed
   from the stores' own pages** (the owner: "specific overrides for Chrome Web Store and Firefox stores so that we can install
   directly through their pages"). No silent installs, no updates without the person (an update that asks more is asked again).
3. **Grants**: what an extension asks for, API permissions and site access, granted **at install**, all or nothing, worded per
   permission (the owner chose this over asking site by site); narrowed any time from the extension's menu.
4. **Private windows**: off by default per extension, on by the person's choice; never storage shared with private pages.
5. **Sunset's own pages and the vault**: no extension runs in Sunset's pages (`sunset:`), its pop-up of site settings, or
   (later) the credentials' views.
6. **Visible**: each extension's action (its badge, its popup) in the sidebar's header row, between the sidebar button and the
   traffic lights (the owner); a list in Settings ▸ Extensions with what each may do and where.
7. **Blockers**: an extension's `declarativeNetRequest` and Sunset's own blocker both apply (the owner).
8. **Not now**: `chrome.proxy` (t13), native messaging (a host app: off).

## Consequences

- The tabs, windows and Spaces map onto WebKit's protocols; Spaces are not windows to extensions (an extension sees the window
  and its shown tabs).
- Each grant, prompt and refusal is tested (an extension asking a host not granted runs nowhere, as probed).
- What Chrome has and WebKit lacks is filled later, as driceroland/Search does (0046 D), each with its policy.
