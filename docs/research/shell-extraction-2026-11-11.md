# Sunset's shell as a reusable package: what is in the way, and the smallest plan

Asked 2026-11-10 (t111; n40-n44). Read from the source at a9da0e9; nothing here is built yet.

## What is already generic

`SunsetPane` has no dependency and no terminal in it: `Workspace` (ordered tabs, each a split tree of `PaneID`), `SplitLayout`/`SplitGeometry`, drop
zones, `TabDropAction`, `CloseConfirmation`, `SavedSession`. It is tested alone. A tab now carries a name and an icon of the user's (27dc877).

## What ties the shell to the terminal (all in `SunsetApp`)

| Where | Tie |
| --- | --- |
| `TabsModel` | `[PaneID: TerminalModel]`, makes and stops shells, asks the foreground command to decide "busy" |
| `PaneArea` | builds `TerminalRepresentable`, applies the terminal's top inset |
| `TabLabel`, `SidebarRow` | read directory, foreground command, progress from `TerminalModel` |
| `TabPreviewCard` | shows the terminal's `IOSurface` |
| `SavedWindow` | stores one directory per pane, nothing else |
| `SunsetPane.TabGlyph` | terminal notions (folder, command) in the otherwise generic module |

`SunsetApp` is an executable target: nothing in it can be imported or unit-tested.

## Plan: two modules, not five

1. **`SunsetPane` stays the model**, and gains: a content descriptor per pane (`kind` + opaque `Data`, written by the content, restored through a registry),
   replacing `SavedWindow.directories` with a migration; the folder tree (t112); Spaces (t110).
2. **One new library target for the shell's views** (sidebar, tab bar, pane area, drop, command bar), importing `SunsetPane` and `SunsetConfig` only. It
   sees content through one small `@MainActor` protocol, roughly: `title`, `icon`, `activity` (progress), `closeRisk` (none / running / unsaved, with a
   sentence), `setState(focused:visible:)`, `stop()`, `descriptor`, and a view supplied by a factory closure registered per kind **in this target, not in
   the model**. The terminal becomes the first adapter, in the app.
3. **Prove it with a second, trivial content kind** (a text note) before anything is frozen. Only then WebPane and MarkdownPane.
4. Splitting it out into its own repository comes last, when the app is a thin shell over it; the package boundary inside this repository is the test.

Things the first draft got wrong, to keep out: the icon type was the terminal's; "busy" stood for both "show a spinner" and "ask before closing" (a page
loading is the first, an unsaved document the second); a document was the same thing as the view on it (one document may be in two panes); identity was
mutable.

## The content kinds asked for

- **Web (n42, t114).** First on the system's WebKit: `WKWebView` (or `WebPage` on macOS 26), one `WKWebsiteDataStore(forIdentifier:)` per Space. Using
  the **latest WebKit** is a goal of the owner's (2026-11-11), so the pane must not assume the system's: keep everything WebKit-specific behind the
  adapter. An earlier version of this note said an app cannot use another WebKit build; that was too strong and unverified. WebKit is open source and
  its own tools run an app against a built `WebKit.framework`; whether a build can be shipped inside a signed, hardened app (its XPC services, size,
  updates, private entitlements) is the investigation, t119. Search (see `search-browser-review-2026-11-11.md`) uses the system engine only. Content
  blocking and Chrome extensions are later steps.
- **Markdown (n43, t115).** `AemiMarkdown/Apps/MarkdownLook` has a library, `MarkdownLookKit` (macOS 26): HTML renderer, a native view held to the page
  (its ADR 0005), source highlighting, `LabSession`. The editor itself (`SourceEditor`, an `NSTextView`), saving (`AtomicFile`) and commands are in the
  app target `App/`, not the kit: they would have to move into the kit before Sunset can use them. Its dependencies (aemi, AemiTextUI, AemiMermaid,
  AemiHMMML) would come with it, so this belongs in an adapter target, never in the shell.
- **Folders, names, icons (n40, n41).** Model first: `Workspace` goes from a list to a tree whose leaves are today's tabs; a folder has a name, an icon and
  a colour, and is not a directory on disk. Names and icons of tabs exist in the model; no UI yet.

## Order

Set by the owner on 2026-11-11: OSC (t58, t108) and performance (t100, then t52/t61/t62/t64) come first. After them: t113 UI and t116 (small) ->
content descriptor + protocol + terminal adapter + note kind (t109) -> Web pane on system WebKit (t114) with t119 alongside -> folders (t112) ->
Spaces (t110) -> Markdown (t115) -> content blocking, then extensions -> extraction (t111).
