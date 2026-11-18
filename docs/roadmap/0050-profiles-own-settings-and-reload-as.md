---
status: not-started
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
| A | The model: a profile's overrides over the app's settings, inheriting what it does not set; read, written, migrated | t9 | not-started |
| B | Settings: a profile picker over the four groups, "Same as the app" per setting | t9 | not-started |
| C | Pages made with their profile's settings, and remade when they change | t9 | not-started |
| D | Reload as: the tab's menu and the address bar's; the tab keeps its place, its mark | t10 | not-started |
