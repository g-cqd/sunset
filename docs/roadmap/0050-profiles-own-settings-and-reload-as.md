---
status: done
blocked-by: nothing
date: 2026-11-18
---

# 0050 — A profile's own settings, and Reload as another profile

The owner's notes n1 and n2, decided 2026-11-18: a profile may have its own (the rest shared):

- web, sites: what Sunset appears as by default, the sites' rules (Appears as, Opens in), their permissions and zoom;
- web, privacy and blocking: content blocking and its lists, tracking protection, whether history is kept;
- web, search and home: the search engine, the new tab's page, the address suggestions;
- network: the proxy (and later the resolver), set for the whole app, a profile's own winning for its pages (ADR-0079).

Reload as another profile: the same tab, where it is in the current Space, loaded again with the other profile's data, a
small mark showing that profile.

| Step | What | Task | Status |
|---|---|---|---|
| A | The model: a profile's overrides over the app's settings, inheriting what it does not set; read, written, migrated (`ProfileOverrides`, `Profile.overrides`; a session's "Between runs" carried over) | t9 | done |
| B | Settings: "Settings for" at the top (all profiles or one); with a profile, only the sections, topics and options a profile can set; a setting of its own says so, with Use All Profiles' Setting (ADR-0083) | t9 | done (seen) |
| C | Pages made with their profile's settings (search, suggestions, browser shown, blocking, permission defaults, downloads, what is kept), its store's proxy at once | t9 | done but: open pages keep theirs until reloaded; not seen in a page |
| E | A profile's own site rules (the owner's answer: "that profile only"): set from a page of a profile, for it alone; with none, all profiles' apply (the first profile's are all profiles'). The browser shown, the Space it opens in, zoom, blocking paused, data kept, what sites may do; Each site with a profile chosen lists and resets its own | t9 | done (Each site seen); not per profile: elements hidden (one compiled list for every page), the Websites page's list of answers |
| D | Reload as: the tab's menu and the address bar's (Reload As › each other profile); the tab keeps its place, its address and history, the other profile's store and settings, a mark with that profile's name; back to its Space's, the mark goes; kept in the session (`as`) | t10 | done (seen) |
