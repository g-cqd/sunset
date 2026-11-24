package import SunsetPane
package import SwiftUI

/// The card of a folder of the Favorites under the pointer: "the list of tabs present in the folder, not a tree", open
/// ones first, the most recently used first, then the others in the folder's order
/// (`FavoritesModel.previewEntries(in:)`). At most `limit` rows, then how many more.
package struct FolderPreviewCard: View {
    let folder: Favorites.Folder
    let entries: [Favorites.Entry]
    let kept: FavoritesModel
    let layout: ShellSettings.Layout

    package static let width = 260.0
    static let limit = 8
    private static let row = 24.0
    private static let header = 30.0

    package init(folder: Favorites.Folder, kept: FavoritesModel, layout: ShellSettings.Layout) {
        self.folder = folder
        self.entries = kept.previewEntries(in: folder.id)
        self.kept = kept
        self.layout = layout
    }

    /// Its height: the folder's name, a row a tab, and one for how many more.
    package var height: Double {
        let rows = min(entries.count, Self.limit) + (entries.count > Self.limit ? 1 : 0)
        return Self.header + Double(max(rows, 1)) * Self.row + 2 * Design.Space.m
    }

    package var body: some View {
        let shape = RoundedRectangle(cornerRadius: Design.Radius.small(layout) + Design.Space.s, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: GlyphSpacing.toText) {
                FolderGlyph(folder: folder, open: !folder.isCollapsed)
                Text(folder.name).font(Design.Text.title).lineLimit(1)
            }
            .frame(height: Self.header, alignment: .leading)
            if entries.isEmpty {
                Text("No tabs").foregroundStyle(.secondary).frame(height: Self.row)
            }
            ForEach(entries.prefix(Self.limit), id: \.id) { entry in row(entry) }
            if entries.count > Self.limit {
                Text("\(entries.count - Self.limit) more").foregroundStyle(.secondary).frame(height: Self.row)
            }
        }
        .padding(.horizontal, Design.Space.l)
        .padding(.vertical, Design.Space.m)
        .frame(width: Self.width, alignment: .leading)
        .surface(shape, shadow: .popover, shaded: true)
        .allowsHitTesting(false)
    }

    /// A tab of the folder: its icon and name; one not open is dimmed, as its row is.
    private func row(_ entry: Favorites.Entry) -> some View {
        let saved = entry.home.contents[entry.home.focused]
        let model = entry.open.flatMap { kept.contents[$0.focused] }
        let title = entry.title ?? model?.title ?? saved.map { TabLabel.title(of: $0, command: entry.command) } ?? ""
        return HStack(spacing: GlyphSpacing.toText) {
            TabIcon(model: model, icon: entry.icon, saved: saved, savedCommand: entry.command, showsProgress: false)
            Text(title).lineLimit(1).foregroundStyle(entry.isOpen ? .primary : .secondary)
        }
        .frame(height: Self.row, alignment: .leading)
    }
}
