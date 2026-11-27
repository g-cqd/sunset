import SunsetShell
import SunsetShellModel

/// The menus' commands the command bar offers when what is typed names one (`AppCommand.table`): after what was typed,
/// so that Return still does what it did. Each says its menu and its key.
enum CommandRows {
    /// The rows for `typed` (none with an engine's chip: nil): the commands that would do something now.
    @MainActor static func rows(typed: String?, tabs: TabsModel) -> [ChoiceRow] {
        guard let typed else { return [] }
        let target = AppCommandRunner.Target.acting
        return AppCommand.matching(typed: typed, scopes: tabs.scopes)
            .filter { AppCommandRunner.isEnabled($0.id, on: target) }
            .map { row($0, tabs: tabs, target: target) }
    }

    /// A command, run as its menu item runs it.
    @MainActor private static func row(_ command: AppCommand, tabs: TabsModel, target: AppCommandRunner.Target)
        -> ChoiceRow
    {
        let accessory = [command.menu, command.key?.symbols].compactMap(\.self).joined(separator: "  ")
        return ChoiceRow(
            id: "command \(command.id.rawValue)",
            glyph: .symbol(command.symbol),
            title: command.title,
            accessory: accessory,
            actions: [
                ChoiceAction(command.title, symbol: command.symbol) {
                    tabs.bar = nil
                    // The Library opened, not closed, from the bar.
                    if command.id == .library {
                        if !tabs.sections.isLibraryOpen { tabs.sections.toggleLibrary() }
                    } else {
                        AppCommandRunner.run(command.id, on: target)
                    }
                }
            ]
        )
    }
}
