# Panes that are not terminals: the first slice (t109)

Follows `shell-extraction-2026-11-11.md`. Decided here; the code follows in two commits.

## What a pane holds

The model (`SunsetPane`) knows nothing of what is in a pane, only how to bring it back:

```swift
public struct PaneDescriptor { var kind: String; var state: [String: String] }   // "terminal" {"directory": …}, "note" {"text": …}, later "web" {"url": …}
SavedWindow.contents: [PaneID: PaneDescriptor]                                    // replaces `directories`; an old session file still reads
```

Strings, not opaque bytes: the session file stays readable and a kind this build does not know is kept as it is and written back, not dropped (a
session opened by an older build must not lose its web tabs).

The shell sees content through one protocol, in the app for now (it moves with the views when they become a library):

```swift
@MainActor protocol PaneContent: AnyObject {
    var title: String { get }                 // what the program or page calls itself
    var detail: String? { get }               // a second line: a directory, an address
    var glyph: PaneGlyph { get }              // the tab's own picture: a terminal's folder or command mark, or a symbol
    var progress: Double? { get }             // activity, for the bar under the title
    var closeWarning: String? { get }         // why closing now would lose something, asked at the moment of closing; nil closes at once
    var descriptor: PaneDescriptor { get }    // how to bring it back
    var onExit: () -> Void { get set }        // it ended by itself
    var onFocusRequest: () -> Void { get set }
    func setState(focused: Bool, visible: Bool)
    func stop()
    func makeView(_ context: PaneViewContext) -> AnyView
}
```

Kept apart on purpose: `progress` (a page loading, a build running) and `closeWarning` (a command running, later an unsaved document). The first draft
had one "busy" for both.

`TabsModel` holds `[PaneID: any PaneContent]` and makes content through one closure, `makeContent(PaneDescriptor?)`, given by the scene: nil is a new
terminal, a descriptor is restored by its kind, and a kind this build cannot make becomes a placeholder that keeps the descriptor. What only a terminal
has (font, colours, the top inset, copy and paste, the screen preview) is reached by `tabs.terminal(pane)`, a cast, and does nothing for other kinds.

## The proof: a note

A second kind with nothing in common with a terminal, to show the protocol is enough before Web and Markdown lean on it: a plain text note
(`NoteContent`, a `TextEditor`), made with Panes > New Note, saved in the session by its text, split, dragged, renamed and closed like any tab.

## Not in this slice

A document shown in two panes (one `NoteContent` per pane for now); the views as a library target; folders; Spaces.
