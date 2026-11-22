# 0005 — How a setting is worded

Settings are worded as macOS words its own, with VMRunner as a model. Read on 2026-11-17: VMRunner's Settings (`Sources/VMRunner/Views/Settings/SettingsView.swift`) and
macOS's System Settings (General, Appearance, Desktop & Dock, Privacy & Security). Both word a setting the same way:

| | VMRunner | System Settings |
|---|---|---|
| A switch | "Keep macOS restore images after installing", "Let scripts and AI agents control machines" | "Show scroll bars", "Allow wallpaper tinting in windows", "Ask to keep changes when closing documents" |
| A menu's name | "Default Mac model for ipsw.me" | "Appearance", "Accent color", "Default web browser", "Click in the scroll bar to" (the one fragment, kept by Apple) |
| A menu's values | — | "Light", "Dark", "Auto"; "Always", "When scrolling"; "Jump to the next page" |
| A group | "Disk space", "Input", "Automation" | "Appearance", "Windows", "Widgets" |
| The text under it | "A restore image is 20–27 GB and only needed once." | one or two sentences, grey, under the control |

## The rules

1. **A name is a phrase, not a sentence.** A switch is named by what turning it on does, a verb first, in sentence case:
   "Show the sidebar", "Clear history when Sunset quits". A menu, a field or a number is named by what it sets, a noun
   first: "Address field", "Window bar position". Never a fragment its values finish ("The window bar is at the").
2. **No article first.** Not "The", "A" or "An" at the start of a section's, a group's or a setting's name, nor of a menu's
   value: "Site icon", not "The site's icon"; "Trash", not "The Trash".
3. **No explanation in the name.** What a parenthesis would say goes to the text under it: "Option sends Escape", and
   "As Meta, for the shell's and editors' keys." below; units go in the number's unit, not its name.
4. **No "group: setting".** A name prefixed by its group ("Traffic lights: inset") says the group in the group's name and
   the setting in its own: "Traffic light inset".
5. **One spelling: macOS's.** American, as the system's own words beside ours: color, favorite, gray, center.
6. **The text under a setting** is one or two plain sentences, ending with a period, at most 200 characters. What needs
   more is help, not a note.
7. **Groups and sections** are nouns: "Features", not "What Sunset does".

The rules are checked by `SettingsWordingTests` over every section, group, option, label, value and note of
`SettingsSection.all`.
