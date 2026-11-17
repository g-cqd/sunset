---
status: in-progress
blocked-by: nothing
date: 2026-11-17
---

# 0040 — Settings written as settings are written

The owner, 2026-11-17: "the settings wording, naming are not written as settings should, for example 'The <something>' as
either a title or an option is usually not how you do it, i think the vm runner project also shows how settings can be
written correctly".

| Step | What | Status |
| --- | --- | --- |
| A | Read how VMRunner and macOS's System Settings word titles, options, sections and the notes under them; write the rules down (design) | done: docs/design/0005-settings-wording.md |
| B | A gate: titles and options do not start with an article, are in title case or sentence case as the rules say, notes are sentences of at most a set length | done: `SettingsWordingTests` (red: five rules broken) |
| C | Every title, option and note of `SettingsOption+*.swift` and the Settings pages rewritten to the rules | done for the options, their labels, values and notes, and three sheets' spellings; the hand-built pages (Websites, Profiles, Storage) read by eye only |
| D | Seen in Settings: sections and topics read right | not-started |

## Not done

D. A gate over the hand-built Settings pages' strings. The longer notes cut to 200 characters lost detail that belongs
in help (roadmap 0041 C): the features' hiding, profiles and Spaces, the User-Agent's scripts.
