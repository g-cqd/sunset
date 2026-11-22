import SunsetPane
import SwiftUI

/// The menu of a kept entry, the same wherever the entry is shown (a row of the Favorites, a tile of the Pinned grid, a
/// tab of the built-in bar): where it is kept (pinned, a favourite, a tab again), its name and icon, its command, what
/// it starts from, and unloading or deleting it.
struct KeptEntryMenu: View {
    let tabs: TabsModel
    let entry: Favorites.Entry
    /// Whether the row can be renamed and given an icon where it is (the built-in bar's tabs cannot).
    var editsInPlace = true
    var animation: Animation?

    private var isPinned: Bool {
        tabs.isPinned(entry.id)
    }
    private var runsTerminal: Bool {
        tabs.runsTerminal(entry)
    }
    private var keeper: FavoritesModel {
        tabs.keeper(of: entry.id)
    }

    var body: some View {
        Button(entry.isOpen ? "Show" : "Open") { tabs.select(entry: entry.id) }
        Divider()
        if isPinned {
            Button("Unpin") { withAnimation(animation) { _ = tabs.release(entry: entry.id) } }
            Button("Move to Favorites") { withAnimation(animation) { _ = tabs.favorite(pinned: entry.id) } }
        } else {
            Button("Pin") { withAnimation(animation) { _ = tabs.pin(entry: entry.id) } }
                .disabled(!tabs.canPin(.node(entry.id)))
            Button("Remove from Favorites") { withAnimation(animation) { _ = tabs.release(entry: entry.id) } }
        }
        Divider()
        if editsInPlace {
            Button("Rename") { tabs.renamingRow = .node(entry.id) }
            Button("Change Icon\u{2026}") { tabs.iconRow = .node(entry.id) }
        }
        // Run Command Now with Option.
        if runsTerminal {
            Button("Edit Command\u{2026}") { tabs.editingCommand = entry.id }
                .modifierKeyAlternate(.option) {
                    if entry.isOpen, entry.command != nil {
                        Button("Run Command Now") { keeper.runCommandNow(entry.id) }
                            .disabled(!keeper.isTrusted(entry.id))
                    }
                }
        }
        PaneActionsMenu(tabs: tabs, panes: entry.open?.panes ?? []) { tabs.select(entry: entry.id) }
        Divider()
        // Where it starts from: gone back to, or set to where it is now. Set it to where it is now with Option, open.
        Button(isPinned ? "Reset to Where It Was Pinned" : "Reset to Home") { tabs.reset(entry: entry.id) }
            .modifierKeyAlternate(.option) {
                if entry.isOpen {
                    Button(isPinned ? "Pin Where It Is Now" : "Set Home to Current") {
                        keeper.setHomeToCurrent(entry.id)
                    }
                }
            }
        if entry.isOpen {
            Button("Unload") { tabs.unload(entry: entry.id) }
            if let open = entry.open, open.isSplit {
                // Any pane out of a kept split, into a tab of its own.
                Menu("Move Pane to Its Own Tab") {
                    ForEach(open.panes, id: \.self) { pane in
                        Button(tabs.content(pane)?.title ?? "Pane") { tabs.separate(pane: pane) }
                    }
                }
            }
            // While it is open: unloading it lets go.
            KeepAwakeMenu(tabs: tabs, entry: entry.id)
        }
        Divider()
        Button("Delete", role: .destructive) { tabs.delete(entry: entry.id) }
    }
}
