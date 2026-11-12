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

    @Test func `an answer is kept by site, with or without www, in its file; forgetting it brings the default back`() {
        let path = NSTemporaryDirectory() + "perm-\(UUID().uuidString).json"
        let store = SitePermissions(path: path)
        store.set(.allow, .camera, for: "www.Meet.com")
        store.set(.deny, .notifications, for: "news.com")
        let read = SitePermissions(path: path)
        #expect(
            read.answer(.camera, for: "meet.com") == .allow && read.answer(.notifications, for: "news.com") == .deny
        )
        #expect(read.sites(for: .camera).map(\.host) == ["meet.com"])
        read.set(nil, .camera, for: "meet.com")
        #expect(SitePermissions(path: path).answer(.camera, for: "meet.com") == .ask)
        #expect(SitePermissions(path: path).answers["meet.com"] == nil)
    }
}
