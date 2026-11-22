import SunsetShell
import SunsetShellModel

/// The menus' commands the command bar offers when what is typed names one: after what was typed, so that Return still
/// does what it did.
enum CommandRows {
    /// The rows for `typed` (none with an engine's chip: nil).
    @MainActor static func rows(typed: String?, tabs: TabsModel) -> [ChoiceRow] {
        guard let typed else { return [] }
        return AppCommandChoices.commands(typed: typed, scopes: tabs.scopes).map { row($0, tabs: tabs) }
    }

    /// A command, run as its menu item runs it.
    @MainActor private static func row(_ command: AppCommandChoices.Command, tabs: TabsModel) -> ChoiceRow {
        let (title, symbol, accessory) = look(command)
        return ChoiceRow(
            id: "command \(title)",
            glyph: .symbol(symbol),
            title: title,
            accessory: accessory,
            actions: [
                ChoiceAction(title, symbol: symbol) {
                    tabs.bar = nil
                    run(command, tabs: tabs)
                }
            ]
        )
    }

    private static func look(_ command: AppCommandChoices.Command) -> (String, String, String) {
        if let section = command.librarySection { return (section.title, section.symbol, "Library") }
        switch command {
            case .importFromBrowser: return ("Import from Another Browser\u{2026}", "square.and.arrow.down", "File")
            case .settings: return ("Settings", "gearshape", "Sunset")
            case .library: return ("Library", "books.vertical", "Sidebar")
            default: return ("Sunset Help", "questionmark.circle", "Help")
        }
    }

    @MainActor private static func run(_ command: AppCommandChoices.Command, tabs: TabsModel) {
        if let section = command.librarySection { return tabs.sections.show(library: section) }
        switch command {
            case .importFromBrowser: AppActions.shared.importFromBrowser()
            case .settings: AppSettings.show(in: tabs)
            case .library: if !tabs.sections.isLibraryOpen { tabs.sections.toggleLibrary() }
            default: AppHelp.show(in: tabs)
        }
    }
}
