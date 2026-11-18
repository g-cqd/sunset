---
status: in-progress (W-a done 2026-11-17; W-g done with W-a, ADR-0052; W-c done 2026-11-18, ADR-0072; W-d done 2026-11-18 but hidden elements (W-e) and keep awake in the panel; W-b deferred by the owner, ADR-0051; the rest not started)
blocked-by: 0018 (each step's own questions); 0019 (the web pane); 0021 (Spaces and profiles)
date: 2026-11-11
---

# 0022 — Web, beyond the first pane

Decided with the owner in refinement session R5 (`docs/refinement/R5-web-beyond-the-first-pane.md`, accepted 2026-11-11), which is the
description to build from. Nothing is built. Each step starts with its own questions.

| Step | What | Task |
| --- | --- | --- |
| W-a | Agent presets (versions baked in at compile time) and the first rung of the disguise: headers; site, Space, profile, default | t121 |
| W-b | The shipped list of site rules, on by default | t154 |
| W-c | Blocking: well-known lists fetched and compiled, on by default, a pause per site | t155 |
| W-d | The site panel, the Sites section of Settings, a site sent to a Space | t156 |
| W-e | Hiding an element for good | t157 |
| W-f | A proxy per profile; widened by the owner (note n75, 2026-11-14): see below | t158, t261 |
| W-g | The second rung: the script-visible identity | t159 |
| Studies | Extensions (t161); bookmarks (t162); passwords and passkeys (t163): each read back before anything is promised | |
| W-h | The third rung: feature probes | t160 |
| E | The own engine, last: the spike on a build from the tip of main, read back (DRM matters especially); then the second build of the app | t119 |

W-e and W-f were placed after the site panel by the assistant; the owner can move them.

Noted by the owner in web step f (2026-11-12), much later: an antivirus check of downloaded files (ClamAV); a study of segmented, more reliable
downloading as aria2c does it.

## Proxies and name resolution (the owner's note n75, 2026-11-14)

His words: "i'd like that proxy extensions work in sunset, and i'd like that we could configure directly proxy for sunset, later for each
profiles or even spaces, and i'd like that we would be able to set up dns over https/tls/quic in sunset directly". Three wishes, none
refined and nothing built (task t261; questions and probes first):

| Wish | Where it goes | What is known, as a claim until probed |
| --- | --- | --- |
| A proxy set in Sunset, for the whole app first, later per profile or per Space | W-f (t158), which no longer waits for profiles for its first form | Apple's documentation lists `WKWebsiteDataStore.proxyConfigurations` (macOS 14 and later), an array of the Network framework's `ProxyConfiguration`. Not tried here: which kinds it takes, whether every path of a store goes through it (downloads, favicons, suggestions, our own `URLSession`s), and where credentials are kept |
| Extensions that set a proxy work | The extensions study (t161) | Whether WebKit's extension engine (`WKWebExtension`, macOS 15.4 and later) offers the `proxy` interface to an extension is not known: to be read in WebKit's source and tried with one such extension |
| DNS over HTTPS, TLS or QUIC, set in Sunset | A probe of its own, before anything is promised | The Network framework has `NWParameters.PrivacyContext.requireEncryptedNameResolution` with a resolver over TLS or HTTPS, for connections an app makes itself; nothing public was found that gives a resolver to a web view, and none for DNS over QUIC. A way that would not need one: a proxy inside Sunset that resolves names itself, which the pages are sent through. Unproven |

## W-a as built: appearing as another browser (2026-11-17; ADR-0051)

Taken before profiles at the owner's asking. His answers are in the ADR.

- **Chrome, Edge, Firefox or Safari on macOS**: what the User-Agent says, in every request of the page, to its scripts,
  and in Sunset's own request for the tab's icon.
- **Per site**: the site's panel in the address field has "Appears as" (Default, Safari, Chrome, Edge, Firefox); the rule
  is for the site and its subdomains, kept sealed, and the page loads again.
- **For every site**: `web.agent`, in Settings > Web > Websites ("Sites see Sunset as"), with the sites that have a rule
  listed under it, each changeable or removed.
- **Versions** are the vendors', written into the build by `Scripts/update-agent-versions.sh` (Chrome 158, Edge 152,
  Firefox 160 on 2026-11-17).

Probed with a server on this machine that says what it was sent (`BrowserAgentTests`, and on screen): the default; a
site's rule on the very navigation that goes to it; `navigator.userAgent`; back to WebKit's own; no `Sec-CH-UA`. Seen in
a test copy: "Appears as" set to Chrome on `localhost`, the page loaded again as Chrome 158, the rule and the icon's
request still Chrome after a quit (`docs/research/web/agent-chrome-on-a-site.png`).

Not done, or not seen:

- **Only the User-Agent**: no client hints (WebKit has none), nothing of what scripts can probe, nothing of the
  connection. A site that checks more than the User-Agent can tell; whether the owner's sites do is his to try.
- **Not seen**: the row in Settings (tested as a setting; not looked at), a real site.
- The search suggestions' request still names Sunset (t290). No shipped list (W-b). The later rungs.

## W-g taken early, and what Sunset asks for by itself (2026-11-17; ADR-0052)

Decided by the builder while the owner was away; his to change.

- **`web.agentScripts`, on by default**: a page shown Chrome or Edge reads Google's vendor, `navigator.userAgentData`
  and a `window.chrome` from its scripts; one shown Firefox reads Firefox's. Off: the User-Agent only.
- **The search suggestions' request** says what a page would say; it named Sunset.

Probed in `BrowserAgentTests` with a server on this machine and a real page: each browser's values read back from the
page's scripts; untouched for Safari and with the setting off. **Not seen on screen, and no real site tried**: whether the
owner's sites now work is his to try, with the setting and the site's rule as the way back.

