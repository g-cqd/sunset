import Foundation
import Testing

@testable import SunsetWeb

@Suite("Page zoom") @MainActor struct ZoomTests {
    @Test func `levels step up and down and stop at the ends`() {
        #expect(ZoomLevels.step(from: 1, by: 1) == 1.15 && ZoomLevels.step(from: 1, by: -1) == 0.85)
        #expect(ZoomLevels.step(from: 3, by: 1) == 3 && ZoomLevels.step(from: 0.5, by: -1) == 0.5)
        #expect(ZoomLevels.step(from: 1.2, by: 1) == 1.25 && ZoomLevels.label(1.25) == "125%")
    }

    @Test func `a site's zoom is kept by host, with or without www, and written to its file`() throws {
        let path = NSTemporaryDirectory() + "zoom-\(UUID().uuidString)/site-zoom.json"
        let store = SiteZoom(path: path)
        store.set(1.25, for: "www.Example.com", remember: true)
        #expect(store.level(for: "example.com") == 1.25 && store.level(for: "other.org") == 1)
        #expect(SiteZoom(path: path).level(for: "example.com") == 1.25)
        store.set(1, for: "example.com", remember: true)
        #expect(SiteZoom(path: path).level(for: "example.com") == 1)
    }

    @Test func `a level not remembered is not written`() {
        let path = NSTemporaryDirectory() + "zoom-\(UUID().uuidString).json"
        let store = SiteZoom(path: path)
        store.set(2, for: "a.com", remember: false)
        #expect(store.level(for: "a.com") == 2 && !FileManager.default.fileExists(atPath: path))
    }
}
