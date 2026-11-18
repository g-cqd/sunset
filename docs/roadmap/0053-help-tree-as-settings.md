---
status: done
blocked-by: nothing
date: 2026-11-18
---

# 0053 — Help's tree is the settings' tree

The owner's note n16 (task t41): "the helper window/scope does not have the same kind of tree than the general settings, you
could harmonize and uniformize that".

| Step | What | Status |
|---|---|---|
| A | Each Help topic names the settings' topic it is about (`HelpTopic.settingsTopic`); Help's own areas (`HelpArea`) removed | done |
| B | Help's list is the settings' sections in their order, with their symbols and rows (`SettingsListRow`), the topics of the shown section under it, all that match while searching; a Settings row last opens the settings of the topic shown | done |
| C | A topic's heading and its tab's detail name its section ("Web › Downloads"), as a settings page's | done |
| D | Settings' Help row opens on the topic of the page shown, else its section's first | done |

Not done: Settings' Help row is only in the Library's list (not in the page's own list when the sidebar does not show it), as
before; sections with no topic (Appearance, Window, Terminal) are not listed in Help.
