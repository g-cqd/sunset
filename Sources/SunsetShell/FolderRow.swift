import SunsetMetrics
import SunsetPane
import SwiftUI
import UniformTypeIdentifiers

/// A folder of the Favorites (R3): an indent per level, a folder icon filled when expanded; a click expands or collapses it, as does the chevron
/// at its trailing edge (where a tab's close button is, shown under the pointer: owner, 2026-11-12); its name is edited in place; a tab or an
/// entry dropped anywhere on it goes inside. It never opens or closes what it holds.
struct FolderRow: View {
    let tabs: TabsModel
    let folder: Favorites.Folder
    let layout: ShellSettings.Layout
    @State private var name: String

    init(tabs: TabsModel, folder: Favorites.Folder, layout: ShellSettings.Layout) {
        self.tabs = tabs
        self.folder = folder
        self.layout = layout
        _name = State(initialValue: folder.name)
    }
    @State private var targeted = false
    @State private var hovering = false
    @Environment(\.accent) private var accent

    var body: some View {
        HStack(spacing: GlyphSpacing.toText) {
            // Under the pointer the fold's chevron takes the icon's place, on the leading edge as every fold's
            // (docs/design/folds-and-menus.md, the owner's note n45).
            if hovering, tabs.renamingRow != .node(folder.id) {
                disclosure
            } else {
                FolderGlyph(folder: folder, open: !folder.isCollapsed)
            }
            if tabs.renamingRow == .node(folder.id) {
                InPlaceNameField(text: $name, commit: commit) { tabs.renamingRow = nil }.inPlaceField()
            } else {
                Text(folder.name).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: layout.closeButtonSize)
        .padding(.leading, layout.tabPaddingLeading)
        .rowHeight(layout, lines: 1, height: Design.Size.favoriteRow)
        .padding(.trailing, layout.tabPaddingTrailing)
        .overlay {
            GeometryReader { proxy in
                if tabs.renamingRow == .node(folder.id) {
                    // Renaming: a button that clears the name in the chevron's place (the owner, 2026-11-17).
                    ClearNameButton(layout: layout) {
                        name = ""
                    }
                    .position(x: proxy.size.width - proxy.size.height / 2, y: proxy.size.height / 2)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous).fill(fill))
        .overlay {
            // Being renamed: the row is the field (note n4).
            if tabs.renamingRow == .node(folder.id) {
                RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
                    .focusHairline(layout, accent: accent.color)
            }
        }
        .contentShape(.rect)
        .keptHover($hovering)
        .hoverPreview(tabs, folder: folder.id)
        .animation(layout.smooth, value: hovering)
        .selectionTaps(tabs, row: .node(folder.id), undo: toggle) { toggle() }
        .onDrag { tabs.itemProvider(for: .entry(folder.id)) }
        .iconPopover(tabs: tabs, row: .node(folder.id))
        .onDrop(
            of: [.plainText, .utf8PlainText],
            delegate: TargetDrop(
                targeted: $targeted,
                allows: { tabs.canDrop(intoFolder: folder.id) },
                drop: { tabs.dropDragged(intoFolder: folder.id) }
            )
        )
        .contextMenu {
            SelectionMenu(tabs: tabs, row: .node(folder.id))
            Button("Rename") { tabs.renamingRow = .node(folder.id) }
            Button("Change Icon…") { tabs.iconRow = .node(folder.id) }
            Button("New Folder Inside") { tabs.newFolder(in: folder.id) }
            Button("Ungroup") { tabs.favorites.edit { $0.ungroup(folder.id) } }
            Divider()
            Button("Delete Folder and Its Contents") { tabs.delete(folder: folder.id) }
        }
    }

    /// Under the pointer: the fold's chevron in the icon's place, right while folded, down while open; a click on it does
    /// what a click on the row does.
    private var disclosure: some View {
        Button(action: toggle) {
            Image(systemName: "chevron.right")
                .font(.system(size: Design.Symbol.badge, weight: Design.Symbol.weight))
                .rotationEffect(.degrees(folder.isCollapsed ? 0 : 90))
                .foregroundStyle(.secondary)
                .frame(width: Design.Size.glyphFrame, height: layout.closeButtonSize)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help(folder.isCollapsed ? "Expand" : "Collapse")
    }

    private var fill: Color {
        if targeted { return accent.color.opacity(Design.Fill.target) }
        if tabs.isMarked(.node(folder.id)) { return accent.color.opacity(Design.Fill.marked) }
        return .primary.opacity(hovering ? Design.Fill.hover : 0)
    }

    /// Folded or unfolded in a stroke (n76): its rows slide in or out, the chevron turns.
    private func toggle() {
        withAnimation(.easeOut(duration: Design.Motion.foldDuration)) {
            tabs.favorites.edit { $0.setCollapsed(!folder.isCollapsed, for: folder.id) }
        }
    }

    private func commit() {
        tabs.favorites.edit { $0.rename(folder.id, to: name) }
        if tabs.renamingRow == .node(folder.id) { tabs.renamingRow = nil }
    }
}
