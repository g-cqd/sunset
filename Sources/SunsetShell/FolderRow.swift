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

    var body: some View {
        HStack(spacing: GlyphSpacing.toText) {
            if let icon = folder.icon, PaneIconView.canShow(icon) {
                PaneIconView(icon: icon).opacity(folder.isCollapsed ? 0.7 : 1)
            } else {
                Image(systemName: folder.isCollapsed ? "folder" : "folder.fill")
                    .font(.system(size: Design.Symbol.row))
                    .foregroundStyle(.secondary)
                    .frame(width: Design.Size.glyphFrame)
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
        .padding(.vertical, Design.rowPadding(layout, lines: 1, height: Design.Size.favoriteRow))
        .padding(.trailing, layout.tabPaddingTrailing)
        .overlay {
            GeometryReader { proxy in
                disclosure.position(x: proxy.size.width - proxy.size.height / 2, y: proxy.size.height / 2)
            }
        }
        .background(RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous).fill(fill))
        .contentShape(.rect)
        .onHover { hovering = $0 }
        .animation(layout.smooth, value: hovering)
        .onTapGesture(count: 2) { tabs.renamingRow = .node(folder.id) }
        .selectionTaps(tabs, row: .node(folder.id)) { toggle() }
        .onDrag { tabs.itemProvider(for: .entry(folder.id)) }
        .iconPopover(tabs: tabs, row: .node(folder.id))
        .onDrop(of: [.plainText, .utf8PlainText], delegate: Drop(tabs: tabs, folder: folder.id, targeted: $targeted))
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

    /// Under the pointer: the folder's chevron, down to expand, up to collapse; a click on it does what a click on the row does.
    private var disclosure: some View {
        Button(action: toggle) {
            Image(systemName: folder.isCollapsed ? "chevron.down" : "chevron.up")
                .font(.system(size: Design.Symbol.badge, weight: .semibold))
                .frame(width: layout.closeButtonSize, height: layout.closeButtonSize)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .opacity(hovering ? 1 : 0)
        .allowsHitTesting(hovering)
        .help(folder.isCollapsed ? "Expand" : "Collapse")
    }

    private var fill: Color {
        let accent = Color(nsColor: .controlAccentColor)
        if targeted { return accent.opacity(0.22) }
        if tabs.isMarked(.node(folder.id)) { return accent.opacity(0.18) }
        return .primary.opacity(hovering ? Design.Fill.hover : 0)
    }

    private func toggle() { tabs.favorites.edit { $0.setCollapsed(!folder.isCollapsed, for: folder.id) } }

    private func commit() {
        tabs.favorites.edit { $0.rename(folder.id, to: name) }
        if tabs.renamingRow == .node(folder.id) { tabs.renamingRow = nil }
    }

    private struct Drop: DropDelegate {
        let tabs: TabsModel
        let folder: Favorites.NodeID
        @Binding var targeted: Bool

        func validateDrop(info: DropInfo) -> Bool { tabs.canDrop(intoFolder: folder) }
        func dropEntered(info: DropInfo) { targeted = tabs.canDrop(intoFolder: folder) }
        func dropExited(info: DropInfo) { targeted = false }
        func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: targeted ? .move : .cancel) }
        func performDrop(info: DropInfo) -> Bool {
            targeted = false
            return tabs.dropDragged(intoFolder: folder)
        }
    }
}
