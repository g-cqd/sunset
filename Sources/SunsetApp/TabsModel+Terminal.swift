import SunsetPane
import SunsetShell
import SunsetTerminal

/// What only a terminal has (its font, its screen, copy and paste): the shell's tab model knows no kind of content, the app knows this one.
extension TabsModel {
    /// The terminal in `pane`, when that is what it holds.
    func terminal(_ pane: PaneID) -> TerminalModel? { content(pane) as? TerminalModel }
    var selectedTerminal: TerminalModel? { shownPane.flatMap(terminal) }
    /// The terminals of this window's tabs and of the kept entry it shows (what a change of font or colours reaches).
    var allTerminals: [TerminalModel] { (workspace.allPanes + (shownEntry?.open?.panes ?? [])).compactMap(terminal) }
}
