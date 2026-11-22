import SunsetPane
import SunsetShell
import SwiftUI

/// The Spaces menu: the Spaces by name, the one before and the one after, and what makes, edits and deletes one. The
/// keys are fixed: Option-Command with a digit or an arrow.
struct SpaceCommands: Commands {
    private let spaces = AppSpaces.all

    var body: some Commands {
        CommandMenu("Spaces") {
            Button("New Space") { AppActions.shared.spaceTabs?.newSpace() }
            Button("Edit Space\u{2026}") {
                guard let tabs = AppActions.shared.spaceTabs else { return }
                tabs.edit(space: tabs.space)
            }
            .disabled(spaces.spaces.count < 2)
            Button("Delete Space\u{2026}") { AppActions.shared.spaceTabs?.deleteSpace() }
                .disabled(spaces.spaces.count < 2)
            Divider()
            Button("Show Next Space") { AppActions.shared.spaceTabs?.stepSpace(by: 1) }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
                .disabled(spaces.spaces.count < 2)
            Button("Show Previous Space") { AppActions.shared.spaceTabs?.stepSpace(by: -1) }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
                .disabled(spaces.spaces.count < 2)
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
