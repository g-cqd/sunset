---
status: accepted
date: 2026-11-17
---

# 0051 — Appearing as another browser changes the User-Agent, per site or for all, and says what it does not change

Roadmap 0022, step W-a, taken before profiles at the owner's asking (2026-11-17). R5 decided a ladder: headers first,
the script-visible identity later, feature probes later still; versions baked in at compile time; site, Space, profile,
default. The owner's answers for the first version:

| Question | The owner's answer |
| --- | --- |
| Which browsers | **Chrome, Edge, Firefox, Safari on macOS** |
| How a site is made to see one | **Per site, from the page**, and **a list in Settings**; "and a possibility to set it to always appear as chrome" |
| A shipped list of sites that need it (W-b) | **Not yet**: start empty, he adds his sites |

## Decision

1. **What changes is the User-Agent**, and it changes everywhere the page says it: the header of every request the page
   makes, `navigator.userAgent`, and the request Sunset itself makes for the tab's icon. Safari is Sunset as it is
   (WebKit's own, named as the installed Safari, R1): no rule and no default is the same as before.
2. **What does not change, said in Settings and here**: the engine is WebKit. No client-hint header is sent
   (`Sec-CH-UA`…): WebKit has none and gives no way to add a header to every request; a site that reads the hints
   Chrome sends sees none. What scripts can probe (`navigator.vendor`, `userAgentData`, features), and the
   connection's own fingerprint (TLS, HTTP/2), are WebKit's. A site that looks further can tell.
3. **A rule is for a site and its subdomains** (`SiteAgents`): the nearest rule wins, a subdomain's own before its
   parent's; never for a bare last label. Kept sealed in the state database, as what a site may do is; not in the
   configuration file. A private page reads the rules and can set one (to say: it is kept).
4. **The default for every site is `web.agent`** (`safari`, `chrome`, `edge`, `firefox`): "always appear as Chrome".
5. **It applies when the view goes to a page**: set as the navigation is decided, by the page's site. Choosing it from
   the site's panel loads the page again. What a page of site A loads from site B is told what A is told.
6. **Versions are the vendors', read from their release feeds by a person** (`Scripts/update-agent-versions.sh` writes
   `AgentVersions.swift`): Chrome 158, Edge 152, Firefox 160 on 2026-11-17. The app never fetches them. The rest of each
   string is what these browsers have frozen (`10_15_7`, `.0.0.0`).

## Found on the way

The request for a tab's icon said `Sunset/<build> CFNetwork/… Darwin/…` to every site, whatever the page said, and
before this step too. It now says what the page says, and is not made when that is not known.

## Not done

- **The search suggestions' request** (to the search engine, not to a site) still says `Sunset/… CFNetwork`: a task.
- The second and third rungs (R5, W-g and W-h); a preset per Space or per profile; Windows, Linux, Android, iOS presets.
- A shipped list of sites (W-b); offering a preset when a site complains.
- Adding a rule in Settings for a site not open (rules are given from a page; Settings changes and removes them).
- A check, at each build, that the versions are not old.
