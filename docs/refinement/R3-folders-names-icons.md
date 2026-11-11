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
