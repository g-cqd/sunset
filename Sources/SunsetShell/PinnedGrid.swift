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
    /// The tile a drag is over, and on which side of it it would land (roadmap 0035 A).
    @State private var tileDrop: (index: Int, after: Bool)?
    @State private var tileWidths: [Favorites.NodeID: Double] = [:]
    @Environment(\.accent) private var accent

    /// A drag under way would be pinned here: the grid is there, even empty, and outlined (the owner, 2026-11-17).
    private var takesDrag: Bool { tabs.dragTargets?.pinned == true }

    var body: some View {
        let entries = tabs.pinnedEntries
        if !entries.isEmpty || takesDrag {
            PinnedTiles {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    tile(entry)
                        .onGeometryChange(for: Double.self, of: { Double($0.size.width) }) { tileWidths[entry.id] = $0 }
                        .overlay(alignment: tileDrop?.after == true ? .trailing : .leading) {
                            if tileDrop?.index == index { dropMark }
                        }
                        .onDrop(
                            of: [.plainText, .utf8PlainText],
                            delegate: PinnedTileDropDelegate(
                                tabs: tabs,
                                index: index,
                                width: tileWidths[entry.id] ?? PinnedLayout.widths.lowerBound,
                                active: $tileDrop
                            )
                        )
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
                // The place kept for what is being dragged in (the owner, 2026-11-17: "an invisible placeholder slot"),
                // outlined as the grid is while the drag is under way.
                if takesDrag {
                    Color.clear
                        .dropTarget(shown: true, targeted: targeted, radius: layout.tabRadius)
                        .accessibilityHidden(true)
                }
            }
            .animation(layout.smooth, value: entries.map(\.id))
            .animation(layout.smooth, value: takesDrag)
            // The tiles reach the rows' edges (the owner, 2026-11-17, roadmap 0035 B); the grid's outline is drawn around them,
            // past the edges, so that it does not move them.
            .background {
                Color.clear
                    .padding(-Design.Space.xs)
                    .dropTarget(shown: takesDrag && !entries.isEmpty, targeted: false, radius: layout.tabRadius)
            }
            .padding(.vertical, Design.Space.xs)
            .padding(.bottom, Design.Space.s)
            .contentShape(.rect)
            .onDrop(of: [.plainText, .utf8PlainText], isTargeted: $targeted) { _ in
                withAnimation(layout.smooth) { tabs.pinDragged() }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Pinned")
        }
    }

    /// Where a dragged tile or tab would land: a line at the side of the tile, in the gap between two.
    private var dropMark: some View {
        Capsule()
            .fill(accent.color)
            .frame(width: Design.Space.hair)
            .padding(.vertical, Design.Space.xs)
            .offset(x: (tileDrop?.after == true ? 1 : -1) * PinnedLayout.gap / 2)
            .allowsHitTesting(false)
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
            .overlay {
                // Asked whether to stop what runs in it (Unload, Reset, Delete): marked as a tab's row is.
                if entry.open.map({ tabs.isCloseArmed($0.id) }) == true {
                    shape.strokeBorder(Color.red.opacity(Design.Fill.armedLine), lineWidth: 1)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help(name(entry))
        .accessibilityLabel(name(entry))
        .accessibilityAddTraits(shown ? .isSelected : [])
        .contextMenu { KeptEntryMenu(tabs: tabs, entry: entry, animation: layout.smooth) }
        // Dragged out: onto the Favorites it is a favourite there, onto the tabs a tab again.
        .onDrag { tabs.itemProvider(for: .entry(entry.id)) }
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
}
