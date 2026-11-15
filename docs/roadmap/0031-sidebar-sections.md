---
status: not-started
blocked-by: the sketches of the bottom row (the owner decides among them)
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

Arc was still not looked at on screen: it is installed on this Mac and was not running, and opening the owner's browser to
look at it is his to allow.

## The owner's answers (2026-11-15, on the sketches)

| Asked | Answer |
| --- | --- |
| Where the opposite panel's switch is | **P3, glyphs at the bottom**; "i'm interested in you proposing multiple sketches so we can decide": several drawings of the bottom row come before it is built |
| The tab sidebar: the Documents heading and the switch | **They can coexist**: the heading has its own toggle and the switch its own setting, neither depending on the other |
| Which sections exist at first | **History, Documents, Downloads, Tabs** (Tabs where the switch is in the tab sidebar) |
| The orders of documents | **Latest Changed (the default), Latest Made, Name, Kind**. Not "Open First" |
| Both sidebars open on different sections | **Yes, each on its own section** |
| What dragging a document's row does | Onto the tab list: **opens it as a tab there** (the document stays in Documents). Onto a pane: **splits it**. Into Favorites: **keeps it there**. Not reordered within Documents (no manual order) |
| Arc | **"Yes, open it"**: to be looked at on screen, its sidebar and Library only, and quit |

## Still to settle

- The look of the bottom row (P3), from several sketches; whether the tab sidebar's switch is the same row.
- What a section's key is, and what the Downloads section is beside the downloads panel of today.

## Not done

Everything.
