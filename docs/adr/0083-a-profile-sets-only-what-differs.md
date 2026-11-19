---
status: accepted
date: 2026-11-18
---

# 0083 — A profile sets only what differs, chosen at the top of Settings

The owner's notes n1, n38 and his answers (2026-11-18): a profile may set search, privacy, network and downloads otherwise;
"they could differ"; the form ("what makes more sense to you?") left to us.

## Decision

1. A profile keeps, with the session, the keys it sets otherwise (`Profile.overrides`), each as the configuration file writes
   it, and only those that differ from all profiles' (`ProfileOverrides.diff`). Setting a profile's value back to all
   profiles' is the same as not setting it: it follows all profiles from then on.
2. The keys a profile may set: `web.engine`, `web.suggestions`, `web.privateSuggestions`, `web.blocking`, `web.agent`,
   `web.agentScripts`, `web.permissions.*`, `web.keep.*`, `web.proxy`, `web.downloadFolder`, `web.askWhereToSave`.
3. Settings has "Settings for" at its top, with more than one profile: all profiles (the file), or one profile. With a profile
   chosen, the sections, topics and options listed are those a profile can set, the same rows writing to the profile; a
   setting of its own says so and can follow all profiles again.
4. A page is made with its profile's settings (`ProfileOverrides.apply` onto all profiles'): what it searches with, its
   suggestions, the browser it is shown as, blocking, what a site gets until answered, where its downloads go. A store gets
   its profile's proxy as soon as it changes. Pages open keep what they were made with until reloaded.
5. Site rules (the owner's answer, 2026-11-18: "that profile only"): a rule set from a page of a profile is that profile's
   alone, kept as `<profile>|<site>` beside all profiles' rules; a profile with none for a site follows all profiles'. The
   first profile's rules are all profiles' (as they always were). The browser shown, the Space a site opens in, its zoom,
   blocking paused, its data kept and what it may do; not the elements hidden (one list compiled for every page).
6. Reload As (roadmap 0050 D): a tab loaded again as another profile takes that profile's store, settings and site rules.

Supersedes: the per-profile "Between runs" rows of ADR-0081 (their choices are carried into the overrides).
