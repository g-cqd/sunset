---
status: accepted (1 and "Not done" superseded by ADR-0101, 4 extended by it)
date: 2026-11-18
---

# 0072 — Ads and trackers are blocked by lists Sunset fetches and converts for WebKit

Roadmap 0022 W-c (R5: well-known lists, fetched and kept current, compiled for WebKit's own blocker, on by default, a
pause per site, a list added by address). R5 left three questions; the owner asked not to be asked (2026-11-18), so they
are decided here, each his to change.

## Decision

1. **Which lists**: EasyList and EasyPrivacy (`web.blockingLists`, https addresses only; others are said and left out).
2. **How often**: a list is fetched again when the copy kept is older than four days (EasyList's own "Expires"); looked at
   when Sunset starts and every six hours while it runs.
3. **What Settings say of the app's own requests**: "Sunset fetches EasyList and EasyPrivacy itself every few days: the
   only requests it makes on its own." Settings > Web > Blocking lists each address, its rules in use, those left out,
   when it was fetched.
4. **Conversion is Sunset's** (`BlockingRules`): host anchors, separators, wildcards, party, resource types, sites,
   `@@` exceptions (after what they undo), whole-site exceptions (`$document`), element hiding (grouped by a hundred
   selectors). Left out and counted, never approximated: regular expressions, `$csp`, `$redirect`, `$rewrite`,
   `$removeparam`, `#?#`, `#$#`, `#@#`, scriptlets, HTML filters, anything not ASCII.
5. **A list can only block, hide or let through** (white paper §9): the only actions written are `block`,
   `css-display-none` and `ignore-previous-rules` (a test feeds hostile lines). Fetched with `WebFetch`: https, at most
   20 MB, no cookies.
6. **The pause is per site** (the site and its subdomains, not a bare last label), from the site's panel, kept sealed
   (`blocking-pauses`), as a site's agent is. It is applied before a page goes to a site, by taking the lists off that
   page's content controller.

## Measured (debug build, one run each: not percentiles)

EasyList 62,631 rules in use (1,399 left out): converted 0.68 s, compiled 1.8 s, 27 MB compiled. EasyPrivacy 56,632
(79 left out): 0.47 s, 1.6 s, 23 MB. The compiled lists are files WebKit maps; their resident cost is not measured.

## Not done

- Adding a list in Settings (the file only); a list's own "Expires" is not read (four days for all).
- What a blocked page loads less, and its time to load, are not measured.
- Pages already loaded take a change of the lists at their next load.
