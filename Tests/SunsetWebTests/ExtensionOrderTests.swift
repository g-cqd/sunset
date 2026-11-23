import Foundation
import Testing

@testable import SunsetWebModel

/// Extensions reordered, and those the header has no room for in a list behind the puzzle piece.
@Suite("The extensions' order and room")
struct ExtensionOrderTests {
    @Test func `moved, the order is kept`() throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "extorder-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        var store = ExtensionStore(root: root, profile: nil)
        let names = ["A", "B", "C"]
        var ids: [UUID] = []
        for name in names {
            let folder = root.appending(path: "src-\(name)")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            ids.append(try store.install(from: folder, name: name, granted: []).id)
        }
        store.move(ids[2], to: 0)
        #expect(store.installed.map(\.name) == ["C", "A", "B"])
        store.move(ids[2], by: 1)
        #expect(store.installed.map(\.name) == ["A", "C", "B"])
        store.move(ids[1], by: 5)
        #expect(store.installed.map(\.name) == ["A", "C", "B"], "past the end: stays")
        #expect(ExtensionStore(root: root, profile: nil).installed.map(\.name) == ["A", "C", "B"], "kept")
    }

    @Test func `as many buttons as fit; the rest behind the puzzle piece, which takes one place`() {
        #expect(ExtensionRoom.shown(count: 3, room: 5) == 3)
        #expect(ExtensionRoom.shown(count: 5, room: 5) == 5)
        #expect(ExtensionRoom.shown(count: 6, room: 5) == 4, "four and the puzzle piece")
        #expect(ExtensionRoom.shown(count: 3, room: 1) == 0, "only the puzzle piece")
        #expect(ExtensionRoom.shown(count: 2, room: 0) == 0)
        #expect(ExtensionRoom.places(width: 100, button: 24, spacing: 4) == 3)
    }

    /// In a tab that is not a web page (a terminal, a document), the extensions' buttons are shown, disabled: an action
    /// there would run for no page.
    @Test func `a button is usable in a web tab and when its extension enables it`() {
        #expect(ExtensionRoom.isAvailable(enabled: true, inWebTab: true))
        #expect(!ExtensionRoom.isAvailable(enabled: true, inWebTab: false))
        #expect(!ExtensionRoom.isAvailable(enabled: false, inWebTab: true))
        #expect(!ExtensionRoom.isAvailable(enabled: true, inWebTab: true, blockedAsPrivate: true), "n99")
    }
}
