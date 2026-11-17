---
status: accepted
date: 2026-11-17
---

# 0052 — A page shown another browser reads that browser from its scripts too; and Sunset's own requests say what a page says

Decided by the builder while the owner was away (2026-11-17: "continue on the chrome work… please take decisions, update
the settings, and don't await for me"). Each point is his to change. It takes R5's second rung (W-g: "the script-visible
identity", "what is set, per browser" left open) earlier than R5 placed it, because the first rung alone is told apart
by the first thing a detection script reads: a User-Agent that says Chrome beside `navigator.vendor` "Apple Computer,
Inc.".

## Decision

1. **`web.agentScripts`, on by default**: a page shown Chrome, Edge or Firefox reads that browser from its scripts too.
   Off: the User-Agent only (ADR-0051). In Settings > Web > Websites, under "Sites see Sunset as".
2. **What is set** (`AgentScript`), before the page's own scripts, in every frame:

   | Shown as | Set |
   | --- | --- |
   | Chrome, Edge | `navigator.vendor` "Google Inc."; `navigator.userAgentData` (brands with the major version, not mobile, "macOS"; `getHighEntropyValues` answers architecture arm, 64 bits, full versions `N.0.0.0`); a `window.chrome` object with `app`, `runtime`, `csi`, `loadTimes` |
   | Firefox | `navigator.vendor` ""; `productSub` "20100101"; `oscpu` "Intel Mac OS X 10.15"; `buildID`; no `window.chrome` |
   | Safari | nothing: Sunset as it is |

3. **The script decides by `navigator.userAgent` alone**, so it always agrees with the header, whatever rule or default
   chose it, and needs no word from the app at each navigation.
4. **The request for search suggestions says what a page would** (`WebSettings.userAgent`: the default browser's
   User-Agent; for Safari, what WebKit says by itself with the installed Safari's version). It said
   `Sunset/<build> CFNetwork/… Darwin/…` to the search engine at each key typed.

## What it does not do, said plainly

- The client-hint **headers** are still not sent: only the script's `userAgentData`. A server that reads `Sec-CH-UA` sees
  none.
- Nothing of what the engine can do changes: features Chrome has and WebKit has not are still missing, and a page that
  takes the Chrome path may ask for them. That is the risk R5 named; the setting and the site's rule are the way back.
- A script that looks at how these values are defined (getters on `Navigator.prototype`) can tell they were put there.
- The connection's fingerprint, layout and drawing are WebKit's.

## Not done

- A choice per site of how far to go (the rung is one setting for all sites).
- The third rung (feature probes), other platforms' presets, a shipped list of sites.
