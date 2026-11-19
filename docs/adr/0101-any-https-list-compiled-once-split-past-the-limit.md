---
status: accepted
date: 2026-11-19
supersedes: ADR-0072 1 (which lists) and its "Not done: adding a list in Settings"; ADR-0072 4 (what is left out) is extended
---

# 0101 — Any https list, compiled once, split past WebKit's limit

## Context

The owner, note n58: "i'd like that we allow using other list for the ad blocking, but i also suspect our performances
regarding ad blocking are very shitty". Measured (diary 2026-11-19-08, release):
- every launch and every six hours converted and compiled every list again: about 0.77 s of the main thread and 2.9 s of
  compiling;
- pages loaded before that ended were not blocked;
- AdGuard Base and the StevenBlack hosts file were refused whole by WebKit;
- OISD stopped at 150,000 rules.

## Decision

1. **Which lists:** EasyList and EasyPrivacy by default. Any https list the person adds in Settings (Add, Remove), at most
   16 (`BlockingListPlan.most`).
2. **Compiled once:**
   - a list's compiled parts are named by a digest of its text and the converter's version, and looked up afterwards;
   - converting runs off the main actor;
   - the lists kept go on pages before any fetch;
   - what no list uses is removed from WebKit's store.
3. **Formats:**
   - Adblock Plus syntax as before;
   - hosts files (`0.0.0.0 host`), never blocking the machine's own names;
   - `#` comment lines are comments.
   - A site must be a host name: a regular expression or a `.*` ending leaves the rule out, since one would sink the whole
     list in WebKit.
4. **Size:** past WebKit's 150,000 rules a list fills up to 4 compiled parts, each with all of its exceptions, since an
   exception undoes only what is before it in its own list. Past 4 parts, the rest is left out and counted.

## Not decided: generic element hiding

EasyList's 137 generic hiding rules (13,638 selectors) cost every document about 7.6 ms, plus about 3 ms per 1,000
elements. Its 10,524 site-specific rules cost nothing measurable elsewhere. The choices, for the owner:
- (a) keep them, as now;
- (b) leave generic hiding out: no cost, some empty ad frames shown on sites no rule names;
- (c) apply it later, from Sunset's own world after the page has loaded, only for the selectors that match. Most of the cost
  goes, but there is a flash of the ad first.

## Not done

- A page's load with the network, on real sites, with and without blocking: blocked requests save time there.
- A comparison with Safari and a content blocker.
- The Settings controls seen on screen.
