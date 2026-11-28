import SunsetShell
import SunsetShellModel

/// The menus' commands the command bar offers when what is typed names one (`AppCommand.table`): after what was typed,
/// so that Return still does what it did. Each says its menu and its key.
enum CommandRows {
    /// The rows for `typed` (none with an engine's chip: nil): the commands that would do something now.
    @MainActor static func rows(typed: String?, tabs: TabsModel) -> [ChoiceRow] {
        guard let typed else { return [] }
        let target = AppCommandRunner.Target.acting
        return AppCommand.matching(typed: typed, scopes: tabs.scopes, learning: AppCommandLearning.current)
            .filter { AppCommandRunner.isEnabled($0.id, on: target) }
            .map { row($0, typed: typed, tabs: tabs, target: target) }
    }

    /// The commands' rows put among the bar's `rows`: the one what is typed ran last time first, when it would do something
    /// now; the others after what was typed.
    @MainActor static func place(into rows: inout [ChoiceRow], typed: String?, tabs: TabsModel) {
        let found = self.rows(typed: typed, tabs: tabs)
        let learnt = typed.flatMap { AppCommandLearning.current.command(for: $0) }.map { "command \($0.rawValue)" }
        guard let learnt, let first = found.first(where: { $0.id == learnt }) else {
            rows += found
            return
        }
        rows.insert(first, at: 0)
        rows += found.filter { $0.id != learnt }
    }

    /// A command, run as its menu item runs it.
    @MainActor private static func row(
        _ command: AppCommand,
        typed: String,
        tabs: TabsModel,
        target: AppCommandRunner.Target
    ) -> ChoiceRow {
        let accessory = [command.menu, CommandKeys.shared.sequence(for: command.id)?.symbols].compactMap(\.self)
            .joined(separator: "  ")
        return ChoiceRow(
            id: "command \(command.id.rawValue)",
            glyph: .symbol(command.symbol),
            title: command.title,
            accessory: accessory,
            actions: [
                ChoiceAction(command.title, symbol: command.symbol) {
                    tabs.bar = nil
                    AppCommandLearning.ran(command.id, typed: typed)
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
