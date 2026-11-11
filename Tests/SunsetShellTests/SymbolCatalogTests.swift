import Foundation
import Testing

@testable import SunsetShell

@Suite("The SF Symbols catalog") struct SymbolCatalogTests {
    /// A folder of the system's files with a few symbols, as `CoreGlyphs.bundle` has them.
    private func resources() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "catalog-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        func write(_ value: Any, _ name: String) throws {
            try PropertyListSerialization.data(fromPropertyList: value, format: .binary, options: 0)
                .write(to: folder.appending(path: name))
        }
        try write(
            [
                "character", "character.ar", "character.hi", "folder", "folder.fill", "folder.ar.extra", "iphone",
                "server.rack"
            ],
            "symbol_order.plist"
        )
        try write(["server.rack": ["computer", "network"], "folder": ["directory"]], "symbol_search.plist")
        try write(["folder": ["objectsandtools"], "server.rack": ["devices"]], "symbol_categories.plist")
        try write(["iphone": "This symbol may only be used to refer to Apple's iPhone."], "symbol_restrictions.strings")
        try write(
            [["key": "all", "icon": "square.grid.2x2"], ["key": "devices", "icon": "desktopcomputer"]],
            "categories.plist"
        )
        return folder
    }

    @Test func `the system's order, without restricted symbols or the variants drawn for one script`() throws {
        let catalog = SymbolCatalog.load(from: try resources())
        #expect(catalog.symbols.map(\.name) == ["character", "folder", "folder.fill", "folder.ar.extra", "server.rack"])
        #expect(catalog.categories.map(\.key) == ["all", "devices"])
    }

    @Test func `found by the words of the name and by the search words, and within a category`() throws {
        let catalog = SymbolCatalog.load(from: try resources())
        #expect(catalog.search("rack").map(\.name) == ["server.rack"])
        #expect(catalog.search("computer").map(\.name) == ["server.rack"])
        #expect(catalog.search("dir").map(\.name) == ["folder"])
        #expect(catalog.search("", in: "devices").map(\.name) == ["server.rack"])
        #expect(catalog.search("", in: "all").count == 5 && catalog.search("").count == 5)
    }

    @Test func `missing files give an empty catalog, not a failure`() {
        let catalog = SymbolCatalog.load(from: URL(fileURLWithPath: "/nonexistent-\(UUID().uuidString)"))
        #expect(catalog.symbols.isEmpty && catalog.search("anything").isEmpty)
    }

    @Test func `the system's own files are readable on this machine and hold thousands of symbols`() {
        let catalog = SymbolCatalog.load()
        #expect(catalog.symbols.count > 3000, "\(catalog.symbols.count)")
        #expect(catalog.search("folder").first?.name.hasPrefix("folder") == true)
        let bolt = catalog.search("bolt").prefix(3).map(\.name)
        #expect(bolt.first == "bolt", "a name that is the word comes first: \(bolt)")
        #expect(catalog.search("arrow circle").first?.name.contains("arrow") == true)
        #expect(!catalog.symbols.contains { $0.name == "0.circle.ar" })
    }
}
