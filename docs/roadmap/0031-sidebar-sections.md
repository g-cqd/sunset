---
status: in-progress
blocked-by: nothing
date: 2026-11-14
---

# 0031 — Sections in the sidebars: tabs, documents, history

Asked by the owner while answering ST-5 (roadmap 0030; his words are in `docs/refinement/R12-storage-and-the-document-store.md`).
Nothing is built and nothing is decided beyond his words. Task t259 (see the task list for its number).

## What he asked

| Thing | Read as |
| --- | --- |
| "documents should be movable across tabs as standard tabs" | A document's row is dragged as a tab's row is: among the tabs, into Favorites and their folders |
| "a way to toggle having a specific section for documents" | A setting shows or hides the Documents section of the tab sidebar |
| "documents in the opposite sidebar (the one with the history) and we could switch there between history or documents or other things" | The panel on the side opposite the tabs, today the history only, has sections and a switch between them |
| "a setting that would allow having them in an extended original sidebar where it would show history, documents, tabs as sectionned tabs that would change the sidebar content either for the original one or the opposite one" | A row of section buttons (Tabs, Documents, History) changes what a sidebar shows; a setting says which sidebar carries it |
| "check arc behaviour" | See below; to be looked at on screen before the sketches |

## What Arc does (Arc's own help centre and release notes, read 2026-11-14; not looked at on screen here)

| Claim | From |
| --- | --- |
| A Library icon sits in the bottom-left corner of the sidebar | Release notes 2023: "Just click the Library icon in the bottom-left corner of the Sidebar" |
| The Library was first a page of the sidebar itself, reached by swiping past the first Space | Release notes 2022: "Swipe all the way left to get to Library" |
| The Library holds kinds of things, each a section: media, downloads, Easels, Spaces, archived tabs, Boosts | Release notes 2022 to 2024; the export article ("Open your Library, then select Easels") |
| Archived tabs were first reached by a clock icon at the bottom of the sidebar | Release notes 2021 |

## Sketches (2026-11-15)

Drawn by `DesignCatalogTests+Sections.swift` (`SUNSET_CATALOG=<folder> swift test --filter "the sections of the sidebars"`),
with plain shapes: nothing is built.

- `docs/research/sidebar/sections-opposite.png`: the panel opposite the tabs with History, Documents and Downloads. P1 the
  title is a menu; P2 a segmented row of glyphs under the title; P3 the glyphs at the bottom.
- `docs/research/sidebar/sections-sidebar.png`: the tab sidebar. S1 the Documents heading among the tabs (ST-5's choice);
  S2 a switch at the top (Tabs, Documents, History), one section at a time; S3 the same at the bottom; and the sort menu.

Arc, opened in the background on 2026-11-15 with the owner's leave: **it shows a sign-in window and nothing else** (email,
password, "Sign in", "Create an account"), so its sidebar and Library could not be looked at on this Mac. It was quit at
once; nothing was typed. What is known of Arc stays what its help centre says, above.

### The foot (2026-11-15, after the owner chose P3 and asked for several sketches)

Drawn by `DesignCatalogTests+SectionSwitch.swift` (`--filter "the switch at a sidebar's foot"`).

- `docs/research/sidebar/sections-foot.png`: the opposite panel's foot, six looks. B1 glyphs at the leading end; B2 across
  the width; B3 a dot under the one shown, no fill; B4 glyphs with their names; B5 only the one shown says its name; B6 a
  segmented control.
- `docs/research/sidebar/sections-foot-sidebar.png`: the same at the foot of the tab sidebar, with the +. T1 the + first
  (where it is today), T2 the + at the end, T3 as B5, T4 as B3, T5 as B6.

### Arc on screen (2026-11-15, once the owner had signed in; read through accessibility and one picture, in the background)

| Seen | Measure |
| --- | --- |
| The sidebar's foot: a Library glyph at the leading end, the spaces in the middle (the one shown as its icon, the others as dots, in a strip that scrolls), the + at the trailing end | Sidebar 228 pt wide; Library 32 x 32 at 8 pt; the strip 144 pt; + 32 x 32 at 188 pt |
| The Library glyph **widens the sidebar** and replaces its content | 228 pt to 417 pt |
| Its sections are **tabs laid out vertically** at the leading side: a glyph over a name, the one shown filled | Six tiles of 97 x 80 pt (Media, Downloads, Easels, Spaces, Boosts, Archived Tabs), 100 pt apart |
| The section's content is beside them, under a search field that spans the top; lists are headed by day ("Today", "Yesterday", "Earlier This Week") | Content 281 pt wide |
| An arrow at the strip's foot goes back to the tabs | 32 x 32 at the leading end of the foot |

The picture showed the whole window once, with the owner's own tabs and spaces in it, by a crop that failed; nothing of
them is written here and the pictures were deleted. Arc was left running, back on its tabs.

### The Library (2026-11-15, after the owner's note on the foot)

Drawn by `DesignCatalogTests+Library.swift` (`--filter "the Library of the tab sidebar"`):
`docs/research/sidebar/sections-library.png`. The tab sidebar's foot with the Library glyph, room for spaces and the +; then
the extended sidebar three ways: L1 tiles with names as Arc, L2 a rail of glyphs, L3 a rail with the sidebar keeping its width.

## The owner's answers (2026-11-15, on the sketches)

| Asked | Answer |
| --- | --- |
| Where the opposite panel's switch is | **P3, glyphs at the bottom**; "i'm interested in you proposing multiple sketches so we can decide": several drawings of the bottom row come before it is built |
| The tab sidebar: the Documents heading and the switch | **They can coexist**: the heading has its own toggle and the switch its own setting, neither depending on the other |
| Which sections exist at first | **History, Documents, Downloads, Tabs** (Tabs where the switch is in the tab sidebar) |
| The orders of documents | **Latest Changed (the default), Latest Made, Name, Kind**. Not "Open First" |
| Both sidebars open on different sections | **Yes, each on its own section** |
| What dragging a document's row does | Onto the tab list: **opens it as a tab there** (the document stays in Documents). Onto a pane: **splits it**. Into Favorites: **keeps it there**. Not reordered within Documents (no manual order) |
| Arc | **"Yes, open it"**: done, and it showed only its sign-in window (see the sketches) |

### On the foot (2026-11-15)

| Asked | Answer |
| --- | --- |
| The look of the foot | In his words: "the issue i see with this proposition is that we couldn't use the bottom section for future spaces, so i'd say we could have opposite to the + button, a library icon, that would extend the sidebar into a variant we can change its content of through tabs laid out vertically changing the content of the sidebar to each kind of section, only the opposite sidebar could use the bottom icons, where i would say the t5 b6 is more interesting" |
| Read as | The tab sidebar's foot is kept for spaces, later: a Library glyph at one end, the + at the other. The Library extends the sidebar; its sections are vertical tabs. **Only the opposite panel has a switch at its foot, the segmented one (B6)** |
| The title of a section | **Kept** |
| The + of the tab sidebar | **At the end** |
| What is built first | **Both in one step**: the Documents heading (ST-5) and the sections |

### On the Library (2026-11-15)

| Asked | Answer |
| --- | --- |
| Its look | **L2, a rail of glyphs**: names as tooltips, the sidebar grows by the rail only |
| The way back to the tabs | All four: **an arrow at the rail's foot, the Library glyph again, Tabs as the first vertical tab, Escape** |
| Which end the Library glyph and the + are at | **They follow the sidebar's side**: the Library on the window's edge side, the + on the content's side |
| Always there, or a setting | **A setting, on at first** |
| The opposite panel beside it | **The same sections in both** (one implementation, shown in two places) |

## What is to be built (one step, with ST-5 of 0030)

1. The sections as one thing shown in two places: History (as today), Documents (by day; sorted Latest Changed, Latest Made,
   Name or Kind), Downloads. Each keeps its title and a search field.
2. The opposite panel: a segmented switch at its foot (B6) between the three.
3. The tab sidebar's foot: the Library glyph at the window's edge end, the + at the content's end, the middle left free for
   spaces. The Library widens the sidebar by a rail of glyphs (Tabs, Documents, History, Downloads); the way back is the
   rail's foot, the glyph again, the Tabs glyph and Escape. A setting, on at first.
4. The Documents heading among the tabs (0030 ST-5, layout A), with its own toggle, independent of the Library.
5. A document's row dragged onto the tab list opens it as a tab, onto a pane splits it, into Favorites keeps it.

Read by the builder, to be said in the report: the arrow at the rail's foot and "the Library glyph again" are one control
in one place (the rail's foot is where the glyph was), unless the owner wants two.

## Still to settle

- What a section's key is; what the Downloads section is beside the downloads panel of today (the same list, by the
  owner's "one implementation").
- Spaces: not asked, not designed; only their room at the foot is kept.

## The heading taken out (2026-11-15, the same day, once the owner had the build)

In his words: "i don't think i like having the documents header in the tabs list, documents should be standard tabs across
all tabs". It reverses two answers above (ST-5's layout A, a heading among the tabs; and the heading "coexisting" with the
Library by a toggle of its own) and keeps the one he gave first and repeated: a document is a tab like any other.

- The Documents heading is gone from the tab sidebar, with its setting (`sidebar.documents`: 120 keys again; a file that
  still names the key reads without complaint) and with the mark that drew a tab on its document's row
  (`Workspace.Item.shelved`; a window saved with it reads with the tab among the tabs).
- A document is opened from a list (the Library's Documents, the panel opposite the tabs, File > New Document) and is then
  a tab among the tabs, where a new tab goes: moved, split, kept in Favorites and closed as any tab. A click on a document
  that is open shows the tab that has it.
- Not asked, decided here and to be said: a document that is open and dragged from a list opens **another** tab on it where
  it is dropped (before, the tab on its row moved). The rows of a list have no minus any more: a document's tab is closed
  as tabs are.

## The Library widens the sidebar in place (2026-11-15, the owner with the build in hand)

In his words: "you might want to add a little gutter of space between the sidebar of icons for the library sections and the
tabs of the sidebar themselves, also i don't like that opening or closing the library closes or open the sidebar completelz,
it's really the content and the sidebar themselves that should change and expand in place".

- A gutter of 8 pt between the rail and the list (`SectionRail.gutter`); the sidebar is wider by it too.
- The tab sidebar was replaced by another view when the Library opened, so the tabs slid one way and the section came in
  from the other, as if one sidebar closed and another opened (`docs/research/sidebar/library-open-before.png`, the frames
  of it). Now the sidebar is one frame (`SunsetShell/LibraryFrame.swift`): the list keeps its width and its place in it,
  the rail fades in at the window's edge, and what the list shows fades from the tabs to the section where it is
  (`library-open-after.png`). The tabs stay underneath, unseen and out of reach, so going back does not make them again.

## The corner, the top of a section, the panes' background (2026-11-15, the owner with the build in hand)

In his words: "background for documents and all other panes should use the same background we use for terminals screens /
library button does not have concentric corners to the window edges / documents sorting and adding buttons overlap with the
search and the search makes no sense with no documents existing". Diary 2026-11-15-02.

- Every pane that is not a terminal is drawn on the terminal's background, as opaque as the terminal is seen (ADR-0037).
- The bar at the sidebar's foot is 2 pt higher when docked, as far from the window's bottom as from its side, and the corner
  of the button at the window's corner shares its centre (his choice A1 of `docs/research/sidebar/library-corner-sketches.png`;
  as built, `library-corner-built.png`). The + is therefore 2 pt above the card's bottom.
- The title's row of a section is as tall as its buttons (`SectionTop`, `SectionHeading`), and a section with nothing in it has
  no search field.
- Found on the way: a change of tab left the zoom button at the top left (`WindowLights`, the way of ADR-0036 made to hold).

## As built (2026-11-15)

| Part | Where |
| --- | --- |
| A document dragged; a stored document's descriptor | `SunsetPane`: `PaneDragPayload.document`, `PaneDescriptor.document(stored:)` |
| Which section each sidebar is on; the orders; the documents as the shell reaches them | `SunsetShell`: `SidebarSection(s)`, `DocumentSort`, `ListGroup`, `ShelfDocument`, `DocumentShelf`, `TabsModel+Documents`, `TabsModel+Sections` |
| The switch at the panel's foot, the Library's rail, the sidebar's buttons | `SunsetShell`: `SectionSwitch`, `SectionRail`, `SidebarButtons`, `SidebarPinButton` |
| One section's list in both places | `SunsetApp`: `SectionPanel` (+Parts), `SectionList`, `DocumentSectionRow`; `HistoryPanel` is gone, `HistoryRow` and `DownloadRow` are its rows |
| The Library in the tab sidebar; its glyph at the foot | `SunsetApp`: `LibrarySidebar`, `AppSidebar`, `SidebarBottomBar` |
| The store behind it | `SunsetApp/AppDocuments.swift` (list, create, delete) |
| Settings and menus | `sidebar.library`, `sidebar.documentSort`; Settings > Sidebar; File > New Document; View > Library, Documents, Downloads |

Seen in the running app, in the background (the diary has each): a new document as a tab among the tabs, the edited mark,
the title following a save; the Library opened, each glyph of its rail, the arrow and Tabs going back, Escape from its
search field; the opposite panel on Documents while the tab sidebar showed the tabs; a document deleted from a row's menu.
Pictures: `docs/research/sidebar/sections-built.png` (the parts, off screen), `sections-screen.png` (the window).

## Not done, or not seen

- **A drag was not seen in the app** (none can be made in the background): the three drops are tested in the model only.
- Not seen: the sidebar on the left (the rail is then on the left), the floating sidebar with the Library, the order menu
  opened, a download or a visited page in a section (both lists were empty), the search field taking the keyboard when the
  Library opens (the test window is never the key window).
- The arrow at the rail's foot and "the Library glyph again" are one control: the arrow is where the glyph was. View >
  Library closes it too.
- Escape goes back to the tabs only while the keyboard is in the Library's search field.
- The sections have no keys of their own (Cmd-Y is still the history's); what a section's key is was not decided.
- While the Library is open the address field of the tab sidebar is not shown.
- The downloads button of the sidebar's foot is still there beside the Library's glyph, with its popover: two ways to the
  same list.
- Only documents of the store are listed. A file opened with Open File is a tab, not a document of the list.
- A private window lists the same documents; that was not asked.
- A document's text is not searched (it is sealed and is not read to list it): the search is on titles.
- Spaces: only their room at the foot.
