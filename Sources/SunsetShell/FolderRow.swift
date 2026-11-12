import SunsetMetrics
import SunsetPane
import SwiftUI
import UniformTypeIdentifiers

/// A folder of the Favorites (R3): an indent per level, a folder icon filled when open; a click opens or closes it; its name is edited in place; a tab or
/// an entry dropped anywhere on it goes inside. It never opens or closes what it holds.
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

    var body: some View {
        HStack(spacing: GlyphSpacing.toText) {
            if let icon = folder.icon, PaneIconView.canShow(icon) {
                PaneIconView(icon: icon).opacity(folder.isCollapsed ? 0.7 : 1)
            } else {
                Image(systemName: folder.isCollapsed ? "folder" : "folder.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            if tabs.renamingRow == .node(folder.id) {
                InPlaceNameField(text: $name, commit: commit) { tabs.renamingRow = nil }
            } else {
                Text(folder.name).font(.system(size: 12)).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, layout.tabPaddingLeading)
        .padding(.vertical, layout.tabPaddingVertical + 2)
        .background(
            RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
                .fill(
                    Color(nsColor: .controlAccentColor)
                        .opacity(targeted ? 0.22 : (tabs.isMarked(.node(folder.id)) ? 0.18 : 0))
                )
        )
        .contentShape(.rect)
        .onTapGesture(count: 2) { tabs.renamingRow = .node(folder.id) }
        .selectionTaps(tabs, row: .node(folder.id)) {
            tabs.favorites.edit { $0.setCollapsed(!folder.isCollapsed, for: folder.id) }
        }
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
