import SunsetShellModel
import SwiftUI

/// A menu item made from the command table (`AppCommand`): its title, its key, and what it runs.
struct CommandItem: View {
    let id: AppCommand.ID
    /// A title for the state it is in ("Unmute Page"), else the table's.
    var title: String?
    var target = AppCommandRunner.Target.acting
    /// What it runs instead of the table's command.
    var action: (() -> Void)?

    init(
        _ id: AppCommand.ID,
        title: String? = nil,
        target: AppCommandRunner.Target = .acting,
        action: (() -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.target = target
        self.action = action
    }

    var body: some View {
        let command = AppCommand[id]
        Button(title ?? command.title) {
            if let action { action() } else { AppCommandRunner.run(id, on: target) }
        }
        .commandKey(id)
        .disabled(!AppCommandRunner.isEnabled(id, on: target))
    }
}
