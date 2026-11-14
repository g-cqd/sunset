import Foundation
import Testing

@testable import SunsetWeb

@Suite("What sites were allowed") @MainActor struct SitePermissionsTests {
    @Test func `the owner's defaults: asked, pop-ups and sound blocked; a setting changes a default`() {
        let store = SitePermissions()
        #expect(store.answer(.camera, for: "a.com") == .ask && store.answer(.popups, for: "a.com") == .deny)
        store.defaults[.camera] = .deny
        #expect(store.answer(.camera, for: "a.com") == .deny && store.answer(.autoplay, for: nil) == .deny)
    }

    @Test
    func `an answer is kept by site, with or without www, as sealed records; forgetting it brings the default back`()
        throws
    {
        let path = NSTemporaryDirectory() + "perm-\(UUID().uuidString)/state.sqlite"
        let store = SitePermissions(table: try TestState.table("permissions", at: path))
        store.set(.allow, .camera, for: "www.Meet.com")
        store.set(.deny, .notifications, for: "news.com")
        let read = SitePermissions(table: try TestState.table("permissions", at: path))
        #expect(
            read.answer(.camera, for: "meet.com") == .allow && read.answer(.notifications, for: "news.com") == .deny
        )
        #expect(read.sites(for: .camera).map(\.host) == ["meet.com"])
        read.set(nil, .camera, for: "meet.com")
        #expect(
            SitePermissions(table: try TestState.table("permissions", at: path)).answer(.camera, for: "meet.com")
                == .ask
        )
        #expect(SitePermissions(table: try TestState.table("permissions", at: path)).answers["meet.com"] == nil)
    }

    @Test func `the answers of the file of before the database are taken in`() throws {
        let path = NSTemporaryDirectory() + "perm-\(UUID().uuidString).json"
        try Data(#"{"meet.com": {"camera": "allow", "gone": "deny"}}"#.utf8).write(to: URL(fileURLWithPath: path))
        let table = try TestState.table("permissions")
        let store = SitePermissions(table: table)
        #expect(store.importLegacy(at: path) == 1)
        #expect(SitePermissions(table: table).answer(.camera, for: "meet.com") == .allow)
    }
}
