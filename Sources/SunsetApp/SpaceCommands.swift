import SunsetPane
import SunsetShell
import SwiftUI

/// The Spaces menu (R4; roadmap 0021 steps S-b and S-c): the Spaces by name, the one before and the one after, and what
/// makes, edits and deletes one. The keys are fixed until there is a section for keys (the owner, 2026-11-17:
/// Option-Command with a digit or an arrow).
struct SpaceCommands: Commands {
    private let spaces = AppSpaces.all

    var body: some Commands {
        CommandMenu("Spaces") {
            Button("New Space") { AppActions.shared.spaceTabs?.newSpace() }
            Button("Edit Space\u{2026}") {
                guard let tabs = AppActions.shared.spaceTabs else { return }
                tabs.editingSpace = tabs.space.space.id
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
                let name = space.space.name.isEmpty ? "Home" : space.space.name
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
