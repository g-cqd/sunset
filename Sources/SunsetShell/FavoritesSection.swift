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
    /// The row a drag is over, and whether it would land after it.
    @State private var drop: (owner: Favorites.NodeID, place: Bool)?
    @State private var heights: [Favorites.NodeID: Double] = [:]
    @Environment(\.accent) private var accent

    /// One view: the rows, then their line. As two, a modifier on the section (a measure) laid them over each other, the
    /// line across the rows (the owner's screenshot of 13:05, roadmap 0047 D).
    var body: some View {
        VStack(spacing: layout.tabSpacing) { rowsAndLine }
    }

    @ViewBuilder private var rowsAndLine: some View {
        let favorites = tabs.favorites.favorites
        if !favorites.isEmpty {
            // The tree's rows are the tabs' rows: their height and their spacing (owner, 2026-11-13, t227).
            // Between two rows, and at the top and the bottom, a gap that takes a drop (roadmap 0038 B, F).
            let shown = favorites.rows(selected: tabs.workspace.selectedEntry)
                .filter { row in
                    if case .entry(let entry) = favorites.node(row.id) { return tabs.shows(entry) }
                    return true
                }
            VStack(spacing: 0) {
                ForEach(Array(shown.enumerated()), id: \.element.id) { index, row in
                    GapDrop(tabs: tabs, layout: layout, place: tabs.favoritesGap(index), between: index > 0)
                    Group {
                        switch favorites.node(row.id) {
                            case .entry(let entry): entryRow(entry)
                            case .folder(let folder): FolderRow(tabs: tabs, folder: folder, layout: layout)
                            case nil: EmptyView()
                        }
                    }
                    .padding(.leading, Double(row.level) * Design.Space.l)
                    // A folder's rows slide out from under it as it unfolds, back as it folds (n76).
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                GapDrop(tabs: tabs, layout: layout, place: tabs.favoritesGap(shown.count), between: false)
            }
        }
        FavoritesLine(tabs: tabs, layout: layout, visible: !favorites.isEmpty)
    }

    /// An insertion line at the top or the bottom of the row a drag is over.
    @ViewBuilder private func dropMark(_ id: Favorites.NodeID) -> some View {
        if let drop, drop.owner == id {
            // In the gap beside the row, where a drop there would land (roadmap 0038 F), not on the row's edge.
            VStack {
                if drop.place { Spacer(minLength: 0) }
                Capsule().fill(accent.color).frame(height: Design.Space.hair).padding(.horizontal, Design.Space.xs)
                if !drop.place { Spacer(minLength: 0) }
            }
            .padding(.vertical, -layout.gapMarkOutset)
            .allowsHitTesting(false)
        }
    }

    private func entryRow(_ entry: Favorites.Entry) -> some View {
        entryLook(entry)
            .overlay(alignment: .topLeading) {
                // Its command was not run: something other than Sunset wrote it (t145).
                if tabs.favorites.unconfirmed.contains(entry.id) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: Design.Symbol.badge, weight: Design.Symbol.weight))
                        .foregroundStyle(.orange)
                        .help("Its command was not written by Sunset and was not run. Edit Command\u{2026} to see it.")
                        .offset(x: 2, y: 1)
                }
            }
            .awayDot(tabs.isAway(entry: entry), iconCentre: layout.tabPaddingLeading + Design.Size.glyphFrame / 2)
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { heights[entry.id] = Double($0) }
            .hoverPreview(tabs, entry: entry.id)
            .overlay { dropMark(entry.id) }
            .selectionTaps(tabs, row: .node(entry.id)) { tabs.select(entry: entry.id) }
            .iconPopover(tabs: tabs, row: .node(entry.id))
            .onDrag { tabs.itemProvider(for: .entry(entry.id)) }
            .onDrop(
                of: [.plainText, .utf8PlainText],
                delegate: EntryRowDropDelegate.make(
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
            parts: settings.tabs.bar.parts,
            layout: layout,
            button: entry.isOpen ? .unload : .delete,
            open: tabs.isLoaded(entry: entry),
            compact: true,
            marked: tabs.isMarked(.node(entry.id)),
            awake: entry.isOpen && tabs.keepsAwake(entry: entry.id) != nil,
            stopAwake: { tabs.keepAwake(entry: entry.id, until: nil) },
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
        KeptEntryMenu(tabs: tabs, entry: entry, animation: layout.smooth)
    }
}
