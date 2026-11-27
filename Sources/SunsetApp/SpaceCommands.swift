import SunsetPane
import SunsetShell
import SunsetShellModel
import SwiftUI

/// The Spaces menu: the Spaces by name, the one before and the one after, and what makes, edits and deletes one. The
/// keys are fixed: Option-Command with a digit or an arrow.
struct SpaceCommands: Commands {
    private let spaces = AppSpaces.all

    var body: some Commands {
        CommandMenu("Spaces") {
            CommandItem(.newSpace)
            CommandItem(.editSpace)
            CommandItem(.deleteSpace)
            Divider()
            CommandItem(.nextSpace)
            CommandItem(.previousSpace)
            Divider()
            ForEach(Array(spaces.spaces.enumerated()), id: \.element.space.id) { index, space in
                let name = space.space.shownName
                if index < 9 {
                    Button(name) { AppActions.shared.spaceTabs?.show(spaceInOrder: space) }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [.command, .option])
                } else {
                    Button(name) { AppActions.shared.spaceTabs?.show(spaceInOrder: space) }
                }
            }
        }
    }
}
