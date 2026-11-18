---
status: in-progress
blocked-by: nothing
date: 2026-11-18
---

# 0052 — Settings pages in blocks, every control labelled and aligned

The owner's note n13 (task t38): settings "packed", "some input … don't even have any labels", "add more structure and nest
some configurations … separators", the entry points being adding a search engine and the settings per site. Then, the same
day: the "?" of help goes beside a setting's title, or a section's when it explains several controls, so that every control
lines up on the trailing edge and every title on the leading one.

| Step | What | Status |
|---|---|---|
| A | A page is made of blocks (`SettingsBlock`): options grouped under a heading (`grouped(_:)`), and each list (`SettingsControl.Custom.isList`) a section of its own, headed by its title, its note under it; gated by `SettingsBlockTests` (no run of more than six options without a heading, no heading that repeats the page's) | done |
| B | Every row a `LabeledContent`: the title and its "?" leading (`SettingsLabel`), the control trailing; a list's "?" in its heading | done |
| C | The lists as rows: search engines (each folds open on its name and keyword; Name, Keyword, Search address, Suggestion address labelled, with prompts; Remove inside, not in the fold's label), what sites may do, the browser shown to sites, each site, profiles, blocking lists, features | done |
| D | Groups on the dense pages: Startup (Launch, Closing a tab, Closing the last window, Quitting, Keeping awake), Placement (Tabs, Sidebar), Downloads (Saving, Once downloaded), Cursor (Shape and color, Blinking), Materials (Window, Terminal, Bars), Search (Suggestions) | done |
| E | The rest of the pages reviewed one by one for wording (t24) | not-started |

Not done: the pages not named in D have no groups (none has more than six options); the storage rows (Privacy and security)
keep their own layout; a fold's open state is not kept across launches; only part of the pages were seen after the change
(Search with an engine open, Websites, Startup, Profiles, Placement, Features, Blocking, Configuration file, Downloads).
