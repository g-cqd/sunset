import SunsetShell
import SunsetShellModel

/// The menus' commands the command bar offers when what is typed names one (roadmap 0111 G): after what was typed, so
/// that Return still does what it did.
enum CommandRows {
    /// The rows for `typed` (none with an engine's chip: nil).
    @MainActor static func rows(typed: String?, tabs: TabsModel) -> [ChoiceRow] {
        guard let typed else { return [] }
        return AppCommandChoices.commands(typed: typed, scopes: tabs.scopes).map { row($0, tabs: tabs) }
    }

    /// A command, run as its menu item runs it.
    @MainActor private static func row(_ command: AppCommandChoices.Command, tabs: TabsModel) -> ChoiceRow {
        switch command {
            case .importFromBrowser:
                ChoiceRow(
                    id: "command import",
                    glyph: .symbol("square.and.arrow.down"),
                    title: "Import from Another Browser\u{2026}",
                    accessory: "File",
                    actions: [
                        ChoiceAction("Import", symbol: "square.and.arrow.down") {
                            tabs.bar = nil
                            AppActions.shared.importFromBrowser()
                        }
                    ]
                )
        }
    }
}
