import Foundation
import SunsetStorage
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

@Suite("Page zoom") @MainActor struct ZoomTests {
    @Test func `levels step up and down and stop at the ends`() {
        #expect(ZoomLevels.step(from: 1, by: 1) == 1.15 && ZoomLevels.step(from: 1, by: -1) == 0.85)
        #expect(ZoomLevels.step(from: 3, by: 1) == 3 && ZoomLevels.step(from: 0.5, by: -1) == 0.5)
        #expect(ZoomLevels.step(from: 1.2, by: 1) == 1.25 && ZoomLevels.label(1.25) == "125%")
    }

    @Test func `a site's zoom is kept by host, with or without www, as a sealed record`() throws {
        let path = NSTemporaryDirectory() + "zoom-\(UUID().uuidString)/state.sqlite"
        let store = SiteZoom(table: try TestState.table("zoom", at: path))
        store.set(1.25, for: "www.Example.com", remember: true)
        #expect(store.level(for: "example.com") == 1.25 && store.level(for: "other.org") == 1)
        #expect(SiteZoom(table: try TestState.table("zoom", at: path)).level(for: "example.com") == 1.25)
        store.set(1, for: "example.com", remember: true)
        #expect(SiteZoom(table: try TestState.table("zoom", at: path)).level(for: "example.com") == 1)
    }

    @Test func `a level not remembered is not written`() throws {
        let table = try TestState.table("zoom")
        let store = SiteZoom(table: table)
        store.set(2, for: "a.com", remember: false)
        #expect(store.level(for: "a.com") == 2 && table.count() == 0)
    }

    @Test func `the levels of the file of before the database are taken in`() throws {
        let path = NSTemporaryDirectory() + "zoom-\(UUID().uuidString).json"
        try Data(#"{"example.com": 1.5, "b.org": 0.8}"#.utf8).write(to: URL(fileURLWithPath: path))
        let table = try TestState.table("zoom")
        let store = SiteZoom(table: table)
        #expect(store.importLegacy(at: path) == 2 && table.count() == 2)
        #expect(
            SiteZoom(table: table).level(for: "example.com") == 1.5 && store.importLegacy(at: path + ".none") == nil
        )
    }
}
