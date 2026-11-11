package import SunsetPane
package import SwiftUI

/// What is in a pane, as the tabs, the sidebar and the pane area see it: a terminal, a note, later a page or a document. The shell knows nothing else
/// of it (docs/research/pane-content-2026-11-11.md).
@MainActor package protocol PaneContent: AnyObject {
    /// What the program or the document calls itself.
    var title: String { get }
    /// A second line under the title: a directory, an address.
    var detail: String? { get }
    /// The tab's own picture, when the person gave it none.
    var glyph: PaneGlyph { get }
    /// More words it is found by when tabs are searched, beside its title and detail (a terminal: the program in front).
    var searchTerms: [String] { get }
    /// Activity to show under the title, 0 to 1; nil when there is none.
    var progress: Double? { get }
    /// Why closing it now would lose something (a command is running), asked at the moment of closing; nil when it can go at once. Not the same thing
    /// as `progress`: a page that loads can be closed, a command that prints nothing cannot.
    var closeWarning: String? { get }
    /// How to bring it back in another run.
    var descriptor: PaneDescriptor { get }
    /// It ended by itself (the shell exited): the pane closes.
    var onExit: () -> Void { get set }
    /// Its view took the keyboard (it was clicked): its pane is the focused one.
    var onFocusRequest: () -> Void { get set }
    /// Whether it has the keyboard and whether it is on screen (a tab that is not selected is neither).
    func setState(focused: Bool, visible: Bool)
    /// The pane is closing: whatever runs for it ends.
    func stop()
    func makeView(_ context: PaneViewContext) -> AnyView
}

extension PaneContent {
    package var searchTerms: [String] { [] }
}
