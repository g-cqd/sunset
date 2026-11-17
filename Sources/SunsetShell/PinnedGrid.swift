import SunsetMetrics
import SunsetPane
import SwiftUI
import UniformTypeIdentifiers

/// The Pinned grid, at the top of the sidebar (R4; roadmap 0021, P-b; ADR-0050): the app's kept entries as tiles of icons,
/// the same in every Space. A click shows an entry (opening it when it is not open); everything else is in its menu. A
/// loaded entry has a line inside its tile, an unloaded one none. A tab's row dragged over the grid is given a slot, empty
/// and unseen, where it will land; dropped, it is pinned.
struct PinnedGrid: View {
    let tabs: TabsModel
    let layout: ShellSettings.Layout
    @State private var targeted = false
    @Environment(\.accent) private var accent

    private var showsSlot: Bool { targeted && tabs.canPinDragged }

    var body: some View {
        let entries = tabs.pinnedEntries
        if !entries.isEmpty || tabs.canPinDragged {
            PinnedTiles {
                ForEach(entries) { entry in
                    tile(entry).transition(.scale(scale: 0.6).combined(with: .opacity))
                }
                // The place kept for what is being dragged in (the owner, 2026-11-17: "an invisible placeholder slot").
                if showsSlot || entries.isEmpty { Color.clear.accessibilityHidden(true) }
            }
            .animation(layout.smooth, value: entries.map(\.id))
            .animation(layout.smooth, value: showsSlot)
            .padding(.bottom, Design.Space.m)
            .contentShape(.rect)
            .onDrop(of: [.plainText, .utf8PlainText], isTargeted: $targeted) { _ in
                withAnimation(layout.smooth) { tabs.pinDragged() }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Pinned")
        }
    }

    private func tile(_ entry: Favorites.Entry) -> some View {
        let shown = tabs.workspace.selectedEntry == entry.id
        let pane = entry.open?.focused ?? entry.home.focused
        // The corner of a tab's row (the owner, 2026-11-17): a tile is a tab, shown as its icon.
        let shape = RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
        return Button {
            tabs.select(entry: entry.id)
        } label: {
            TabIcon(
                model: tabs.content(pane),
                icon: entry.icon,
                saved: entry.home.contents[pane],
                savedCommand: entry.command
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                shown ? AnyShapeStyle(accent.color.opacity(Design.Fill.target)) : AnyShapeStyle(.quaternary),
                in: shape
            )
            .overlay {
                // Loaded: a line inside the tile, which does not change its size; none when it is not loaded (the owner,
                // 2026-11-17). In the accent's colour for the one this window shows.
                Group {
                    if shown { shape.focusHairline(layout, accent: accent.color) } else { shape.hoverHairline(layout) }
                }
                .opacity(entry.isOpen ? 1 : 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help(name(entry))
        .accessibilityLabel(name(entry))
        .accessibilityAddTraits(shown ? .isSelected : [])
        .contextMenu { menu(entry) }
        .iconPopover(tabs: tabs, row: .node(entry.id))
        // A tile has no text to edit in place: its name is asked beside it.
        .popover(
            isPresented: Binding(
                get: { tabs.renamingRow == .node(entry.id) },
                set: { if !$0, tabs.renamingRow == .node(entry.id) { tabs.renamingRow = nil } }
            ),
            arrowEdge: .trailing
        ) { PinnedRename(tabs: tabs, entry: entry) }
    }

    /// What a tile is called: the name it was given, else its content's title, else what it starts from.
    private func name(_ entry: Favorites.Entry) -> String {
        let own = tabs.name(of: .node(entry.id))
        if !own.isEmpty { return own }
        return entry.home.contents[entry.home.focused].map { TabLabel.title(of: $0, command: entry.command) }
            ?? "Pinned"
    }

    @ViewBuilder
    private func menu(_ entry: Favorites.Entry) -> some View {
        Button(entry.isOpen ? "Show" : "Open") { tabs.select(entry: entry.id) }
        Button("Reset to Where It Was Pinned") { tabs.reset(entry: entry.id) }
        if entry.isOpen { Button("Unload") { tabs.unload(entry: entry.id) } }
        Divider()
        Button("Rename") { tabs.renamingRow = .node(entry.id) }
        Button("Change Icon\u{2026}") { tabs.iconRow = .node(entry.id) }
        Divider()
        Button("Unpin") { tabs.release(entry: entry.id) }
        Button("Delete", role: .destructive) { tabs.delete(entry: entry.id) }
    }
}
