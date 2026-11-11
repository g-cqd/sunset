import SunsetPane
import SunsetShell
import SunsetTerminal

/// What only a terminal has (its font, its screen, copy and paste): the shell's tab model knows no kind of content, the app knows this one.
extension TabsModel {
    /// The terminal in `pane`, when that is what it holds.
    func terminal(_ pane: PaneID) -> TerminalModel? { contents[pane] as? TerminalModel }
    var selectedTerminal: TerminalModel? { workspace.selectedPane.flatMap(terminal) }
    var allTerminals: [TerminalModel] { workspace.allPanes.compactMap(terminal) }
}
