import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner's note n77: a folder has a preview too, "the list of tabs present in the folder, not a tree"; his answer of
/// 2026-11-17 on the order: open ones first, the most recently used first; then the others, in the folder's order.
@MainActor
@Suite("A folder's preview")
struct FolderPreviewTests {
    @Test func `a folder lists its tabs, nested ones too: open ones by last use, then the others in order`() throws {
        let kept = FavoritesModel()
        var folder: Favorites.NodeID?
        var inner: Favorites.NodeID?
        kept.edit { favorites in
            folder = favorites.addFolder(named: "Work")
            inner = favorites.addFolder(named: "Inner", in: folder)
        }
        let parent = try #require(folder)
        func closed(_ name: String, in place: Favorites.NodeID?) -> Favorites.NodeID? {
            let pane = PaneID()
            var id: Favorites.NodeID?
            kept.edit {
                id = $0.addEntry(home: Favorites.Home(layout: .pane(pane), focused: pane), title: name, in: place)
            }
            return id
        }
        func open(_ name: String, in place: Favorites.NodeID?) -> Favorites.NodeID? {
            var tabs = Workspace()
            let made = tabs.add()
            tabs.setTitle(name, for: made.item)
            guard let item = tabs.items.first else { return nil }
            return kept.keep(item, contents: [:], in: place)
        }
        let first = closed("first", in: parent)
        let mail = open("mail", in: parent)
        let deep = closed("deep", in: inner)
        let docs = open("docs", in: inner)
        _ = closed("outside", in: nil)
        kept.noteUsed(try #require(mail))
        kept.noteUsed(try #require(docs))
        let listed = kept.previewEntries(in: parent).map(\.id)
        #expect(
            listed == [docs, mail, deep, first].compactMap { $0 },
            "open by last use, then the others in order (the inner folder came first)"
        )
        kept.noteUsed(try #require(mail))
        #expect(kept.previewEntries(in: parent).first?.id == mail)
        #expect(kept.previewEntries(in: Favorites.NodeID()).isEmpty, "no such folder")
    }
}
