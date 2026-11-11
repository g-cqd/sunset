import Foundation
package import SunsetPane

/// A kept terminal's command (R3, t145): written only through the dialog, sealed when it is saved, typed into the shell when the entry starts, and never run
/// when its seal does not check (another program wrote it into the session file).
extension FavoritesModel {
    /// Whether the entry's command can be run: sealed by this app, for exactly this text.
    package func isTrusted(_ id: Favorites.NodeID) -> Bool {
        guard let entry = favorites.entry(id), let command = entry.command, let sealer else { return false }
        return sealer.verifies(command, seal: entry.commandSeal)
    }

    /// Saves what the person wrote in the dialog, sealed (a blank command removes it). Saving confirms a command that was not trusted.
    package func setCommand(_ command: String, for id: Favorites.NodeID) {
        let seal = sealer?.seal(command.trimmingCharacters(in: .whitespacesAndNewlines))
        edit { $0.setCommand(command, seal: seal, for: id) }
        unconfirmed.remove(id)
    }

    /// Types the entry's command into its focused pane now, when it is open and the command is trusted.
    package func runCommandNow(_ id: Favorites.NodeID) {
        guard let pane = favorites.entry(id)?.open?.focused else { return }
        runCommand(of: id, in: pane)
    }

    func runCommand(of id: Favorites.NodeID) {
        guard let pane = favorites.entry(id)?.open?.focused else { return }
        runCommand(of: id, in: pane)
    }

    private func runCommand(of id: Favorites.NodeID, in pane: PaneID) {
        guard let command = favorites.entry(id)?.command else { return }
        guard isTrusted(id) else {
            unconfirmed.insert(id)
            return
        }
        contents[pane]?.type(command: command)
    }
}
