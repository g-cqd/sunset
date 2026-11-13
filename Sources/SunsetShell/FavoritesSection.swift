import SunsetMetrics
import SunsetPane
import SwiftUI
import UniformTypeIdentifiers

/// The Favorites at the top of the sidebar (R3, R4): kept entries and folders, then a thin line above the window's own tabs. A click opens an entry and
/// shows it; while it is open its row has a faint fill and a minus that unloads it; one that is not open has no fill and an x that removes it.
struct FavoritesSection: View {
    let tabs: TabsModel
    let settings: ShellSettings
    let layout: ShellSettings.Layout
    @State private var drop: (entry: Favorites.NodeID, after: Bool)?
    @State private var heights: [Favorites.NodeID: Double] = [:]
    @Environment(\.accent) private var accent

    var body: some View {
        let favorites = tabs.favorites.favorites
        if !favorites.isEmpty {
            // The tree's rows are the tabs' rows: their height and their spacing (owner, 2026-11-13, t227).
            VStack(spacing: layout.tabSpacing) {
                ForEach(favorites.rows(selected: tabs.workspace.selectedEntry)) { row in
                    Group {
                        switch favorites.node(row.id) {
                            case .entry(let entry): entryRow(entry)
                            case .folder(let folder): FolderRow(tabs: tabs, folder: folder, layout: layout)
                            case nil: EmptyView()
                        }
                    }
                    .padding(.leading, Double(row.level) * Design.Space.l)
                }
            }
        }
        FavoritesLine(tabs: tabs, layout: layout, visible: !favorites.isEmpty)
    }

    /// An insertion line at the top or the bottom of the row a drag is over.
    @ViewBuilder private func dropMark(_ id: Favorites.NodeID) -> some View {
        if let drop, drop.entry == id {
            VStack {
                if drop.after { Spacer(minLength: 0) }
                Capsule().fill(accent.color).frame(height: Design.Space.hair)
                if !drop.after { Spacer(minLength: 0) }
            }
            .allowsHitTesting(false)
        }
    }

    private func entryRow(_ entry: Favorites.Entry) -> some View {
        entryLook(entry)
            .overlay(alignment: .topLeading) {
                // Its command was not run: something other than Sunset wrote it (t145).
                if tabs.favorites.unconfirmed.contains(entry.id) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: Design.Symbol.badge))
                        .foregroundStyle(.orange)
                        .help("Its command was not written by Sunset and was not run. Edit Command\u{2026} to see it.")
                        .offset(x: 2, y: 1)
                }
            }
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { heights[entry.id] = Double($0) }
            .overlay { dropMark(entry.id) }
            .onTapGesture(count: 2) { tabs.renamingRow = .node(entry.id) }
            .selectionTaps(tabs, row: .node(entry.id)) { tabs.select(entry: entry.id) }
            .iconPopover(tabs: tabs, row: .node(entry.id))
            .onDrag { tabs.itemProvider(for: .entry(entry.id)) }
            .onDrop(
                of: [.plainText, .utf8PlainText],
                delegate: EntryRowDropDelegate(
                    tabs: tabs,
                    entry: entry.id,
                    height: heights[entry.id] ?? 32,
                    active: $drop
                )
            )
            .contextMenu { entryMenu(entry) }
    }

    /// A split entry as a split tab is drawn (n55); else one row.
    @ViewBuilder private func entryLook(_ entry: Favorites.Entry) -> some View {
        if (entry.open?.panes.count ?? entry.home.layout.panes.count) > 1 {
            EntryGroupRow(
                entry: entry,
                tabs: tabs,
                selected: tabs.workspace.selectedEntry == entry.id,
                layout: layout,
                marked: tabs.isMarked(.node(entry.id))
            )
        } else {
            singleRow(entry)
        }
    }

    private func singleRow(_ entry: Favorites.Entry) -> some View {
        SidebarRow(
            model: entry.open.flatMap { tabs.favorites.contents[$0.focused] },
            selected: tabs.workspace.selectedEntry == entry.id,
            armed: entry.open.map { tabs.isCloseArmed($0.id) } ?? false,
            name: entry.title,
            icon: entry.icon,
            saved: entry.home.contents[entry.home.focused],
            savedCommand: entry.command,
            showIcon: settings.tabs.bar.showIcon,
            showTitle: settings.tabs.bar.showTitle,
            showDirectory: settings.tabs.bar.showDirectory,
            showProgress: settings.tabs.bar.showProgress,
            layout: layout,
            button: entry.isOpen ? .unload : .delete,
            open: entry.isOpen,
            compact: true,
            marked: tabs.isMarked(.node(entry.id)),
            renaming: tabs.renamingRow == .node(entry.id)
                ? (
                    tabs.name(of: .node(entry.id)),
                    { name in
                        if let name { tabs.rename(.node(entry.id), to: name) } else { tabs.renamingRow = nil }
                    }
                ) : nil,
            close: { entry.isOpen ? tabs.unload(entry: entry.id) : tabs.delete(entry: entry.id) }
        )
    }

    @ViewBuilder private func entryMenu(_ entry: Favorites.Entry) -> some View {
        SelectionMenu(tabs: tabs, row: .node(entry.id))
        Button("Remove from Favorites") { tabs.release(entry: entry.id) }
        Button("Rename") { tabs.renamingRow = .node(entry.id) }
        Button("Change Icon…") { tabs.iconRow = .node(entry.id) }
        Button("Edit Command…") { tabs.editingCommand = entry.id }
        if entry.isOpen {
            if entry.command != nil {
                Button("Run Command Now") { tabs.favorites.runCommandNow(entry.id) }
                    .disabled(!tabs.favorites.isTrusted(entry.id))
            }
            Button("Set Home to Current") { tabs.favorites.setHomeToCurrent(entry.id) }
            Button("Unload") { tabs.unload(entry: entry.id) }
        }
        Button("Delete") { tabs.delete(entry: entry.id) }
    }
}
