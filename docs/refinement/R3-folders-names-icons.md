# R3 — Sidebar folders, pinning, names and icons (roadmap 0018)

Status: **accepted by the owner 2026-11-11** (roadmap 0020, tasks t112, t142-t146). Nothing here is built.

**Amended by R4 the same day** (`R4-spaces-and-profiles.md`, "What this changes in R3"): the section called *pinned* below is **Favorites** (per
Space); **Pinned** is the profile's grid at the top; folders live only in Favorites, so grouping tabs moves them there; "Unpin" is moving an entry
out of Favorites; Cmd-W or a minus unloads a kept entry, and an x on an unloaded one deletes it.

## The owner's answers

| Question | Answer | His note |
| --- | --- | --- |
| What a folder holds | Open tabs, folders, and saved entries that are not open | |
| Nesting | A fixed limit: 4 levels | |
| How a folder is made | Context menu (New Folder; New Folder with This Tab); the + button's menu; selecting several tabs, then Group | Dropping a tab on a tab keeps meaning a split |
| A collapsed folder | Its row, and the selected tab when it is inside | |
| Colour | Only an icon that is a symbol is coloured, in any colour; rows are not tinted | A colour per folder is not really necessary |
| Whose symbol can be coloured | Folders and tabs | |
| Closing a folder | Two entries: Close Folder (closes what is inside, with the confirmation when something runs) and Ungroup (the folder goes, its tabs stay) | See pinning |
| A folder's life | A folder need not be pinned; it lives through sessions until removed by hand, even with nothing in it | |
| With the built-in tab bar | Folders are groups in the bar | They expand and collapse horizontally |
| Cmd-1 to 9, Next / Previous Tab | Count every tab; selecting one in a collapsed folder shows it | |
| Renaming | The name edited in place; a popover for the icon and its colour | |
| Choosing an icon | A searchable grid of symbols, and emojis, as two tabs of the popover | |
| Pinning | A pinned entry is a saved entry: it stays in the sidebar open or not; closing it stops its program or unloads its page and leaves the entry. Pinned tabs and folders are in their own section at the top; a pinned folder's tabs are pinned | |
| What a pinned entry starts from | Where it was pinned: a page its address then, a terminal its directory then | |
| A pinned terminal | A shell in its directory, and optionally a command typed into it when it opens | A dialog to check and edit that command |
| Leaving the sidebar | Unpin (it becomes an ordinary open tab) and Delete (gone at once, with the confirmation when something runs) | Tabs that are open when the window goes are restored according to the restoration settings |
| What a selection of several tabs can do | Group into a folder, close, be dragged together, pin and unpin | |

## The outcome, as one description

The sidebar is a tree. An entry is a tab, a folder, or a saved entry that is not open. Folders nest to four levels, live until removed by hand
(empty or not, across sessions) and are made from the context menu, the + button's menu, or by grouping a selection. A collapsed folder shows its
row, and the selected tab when that tab is inside it. Closing a folder closes what is inside; ungrouping removes only the folder.

The top of the sidebar is the pinned section. What is pinned stays there whether it is open or not: closing a pinned entry stops it and leaves the
entry, and opening it again starts it from where it was pinned (a page at its address, a terminal as a shell in its directory, with the command the
entry holds, if any, shown and edited in a dialog before it is ever saved). A pinned folder pins what it holds. An entry leaves by Unpin, which
makes it an ordinary open tab, or by Delete.

Several tabs can be selected, to group, close, drag, pin or unpin them together.

A name is edited in place. A click on the icon opens a popover with two tabs, a searchable grid of symbols and the emojis, and a colour for an
icon that is a symbol (any colour; on folders and on tabs). Rows are not tinted.

With the built-in tab bar, folders are groups that expand and collapse along the bar.

Costs, as the owner asked to see them. **Memory**: a saved entry that is not open holds a few strings; the symbol and emoji lists are loaded only
while the popover is open. **Speed**: the sidebar draws only the rows on screen; the tree is walked once per change, not per row. **Safety**: the
session file gains a tree and saved entries, read with the same checks as today (a pane in one place only, depth within the limit), and a file from
before them reads as a flat list. **Security**: a command in a pinned terminal is text that will run on a click: it is only ever written by the
person in the dialog, never taken from a program's output or a page, and the dialog shows it whole before saving.

## Steps (each begins with its own questions)

| Step | What | Questions still to ask |
| --- | --- | --- |
| a | The model: the tree in `SunsetPane` (folders to 4 levels, their name and icon, order), the session file and reading old ones | Whether a folder's collapsed state is saved; what happens to a drop that would exceed the limit |
| b | Folders in the sidebar: rows, collapse (with the selected tab shown), drag in, out and between, New Folder, Close Folder, Ungroup | Indentation and the disclosure mark; where a new tab goes when the selected tab is in a folder |
| c | The name in place; the icon popover (symbol grid, emojis, colour) | Where the symbol list comes from; the colour control |
| d | Selecting several tabs: group, close, drag together, pin and unpin | Cmd-click and Shift-click rules; what Return or a plain click does to a selection |
| e | Pinning: the section, saved entries, closing versus deleting, the terminal's command and its dialog | How something is pinned (menu, drag into the section); the divider; whether a pinned page that has moved shows that it is away from home |
| f | Groups in the built-in tab bar | How a group looks collapsed; nested folders in a row (only the top level, or flattened inside the group) |

## Step a, its questions answered (2026-11-11)

| Question | Answer | His note |
| --- | --- | --- |
| How much goes into the model now | All of it: the two sections, folders, kept entries | |
| A folder's collapsed state | Saved with the session | |
| A drop that would nest deeper than four levels | Flattened to fit: the folders that would exceed the limit are dissolved, their entries placed in the deepest allowed folder | |
| Whose are the Favorites, before Spaces | One set for the app, shown in every window | "Any window is within the same big space and same big profile" |
| And the Tabs | They stay each window's | |
| A kept entry shown in two windows | As R4's S-d, now: the window in use takes control and rendering, the other shows the last picture | |
| Reopen Closed Window | Yes, as a later step of its own | |
| The last window closed, then a new one | It shows the Favorites and reopens the tabs of the window just closed | |
| The session file | Same name, no backup | No backward compatibility while the app is being built |
| How it is cut and shown | a1: the model and the session file, shown by tests. a2: the app moved onto it with no visible change. Then the sidebar steps | |

Said plainly: "flattened to fit" loses structure the person made, silently; and two ownership rules now live side by side (Favorites the
app's, Tabs each window's) until Spaces rework the Tabs.

## The Favorites section, its questions answered (2026-11-11, after step a2)

| Question | Answer | His note |
| --- | --- | --- |
| The app and its last window | It quits with its last window, unless a kept entry is still open | A configurable setting |
| Order | The Favorites section first, then folders in it, then names and icons, selection, the tab bar | |
| The library (R8) | First, as its own step with no visible change: `SunsetShell` is created, the tab model, the content protocol and the sidebar move into it behind its own settings type, with unit tests; the Favorites section is then written inside it | |
| Adding to Favorites | Context menu "Add to Favorites"; dragging the tab above the divider (and an entry below it to take it out) | |
| The section's mark | A thin line between Favorites and Tabs, shown when there are favourites or while a tab is dragged | |
| Cmd-1 to 9, Next and Previous | Only what is open is counted: open entries in the order of Favorites, then the Tabs | |
| A new tab while a kept entry is selected | After the tab that was selected before the entry | |
| No tab left, no entry selected | A quiet hint in the pane area | |
| An entry shown in another window | Its last picture, dimmed, with a small label; a click brings it here | |
| With the tab bar or system tabs | Open kept entries show as tabs at the start of the bar, with a small mark | |
| A kept terminal's command and its dialog | A sub-step right after the section | |
| "Set Home to Current" (the assistant's proposition) | Yes | |

Corrected on the way: the question in step a about "a new window after the last one is closed while the app runs" rested on a wrong premise (the
app quits with its last window); the owner's answer above replaces it.

## A kept terminal's command (t145), its questions answered (2026-11-11)

| Question | Answer | His note |
| --- | --- | --- |
| When it is typed | Each time the entry opens from its home, and also at relaunch when the entry was open | |
| How | As if typed, then Return, once the shell has drawn its prompt | |
| Tampering | Stored with a check only Sunset can make (a signature keyed by a secret in the Keychain); a command whose check fails is shown, never run, until confirmed in the dialog | |
| The dialog | "Edit Command…" in the entry's menu, a sheet showing it whole; "Run Command Now" for an open entry | "Both maybe": a wider Entry Settings sheet can come later, with the name and icon popover (step c) |
| When the command ends | The shell stays | |

## Folders in the sidebar (t142), its questions answered (2026-11-11)

| Question | Answer | His note |
| --- | --- | --- |
| How nesting is drawn | An indent per level and a folder icon, filled when open | |
| A new tab while an entry in a folder is shown | In Tabs, as now | |
| New Folder | Makes "New Folder" and edits its name in place | |
| New Folder with This Tab | The tab is kept in a new folder at the end of Favorites | |
| Dropping on a folder's row | Anywhere on it: into it | |
| Close Folder | **Removed.** A folder never opens or closes what it holds | "Folders can't open or close tabs, they're just synthetic organization made to tidy and sort tabs and bookmarks, a reflection of bookmarks worked through a different navigation paradigm" |
| Deleting a folder that holds entries | Deletes the folder and its entries; open ones stop, with the confirmation when something runs | |

This replaces R3's "Close Folder (closes what is inside)".
