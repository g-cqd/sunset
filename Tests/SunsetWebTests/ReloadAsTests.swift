import Foundation
import SunsetPane
import Testing

@testable import SunsetWeb

/// Roadmap 0050 D: Reload as another profile.
@MainActor @Suite("Reload as another profile") struct ReloadAsTests {
    /// One for the suite: the hook is the app's, shared by the tests that run at once.
    private static let workID = UUID()
    private let work = Self.workID
    private let address = URL(string: "https://example.org/a")

    init() {
        let work = Self.workID
        WebProfiles.settings = { profile, like in
            var settings = like
            settings.profile = profile
            settings.agent = profile == work ? .chrome : .safari
            return settings
        }
    }

    @Test func `the page keeps its address, takes the profile's data and settings, and says so; back, the mark goes`() {
        let page = WebContent(url: address, settings: WebSettings())
        page.reload(as: work)
        #expect(page.reloadedAs == OtherProfile(id: work))
        #expect(page.settings.profile == work && page.settings.agent == .chrome)
        #expect(page.url == address)
        #expect(page.descriptor.state["as"] == work.uuidString)
        page.reload(as: nil)
        #expect(page.reloadedAs == nil && page.settings.profile == nil)
        #expect(page.descriptor.state["as"] == nil)
    }

    @Test func `read back from the session as it was left`() {
        let saved = PaneDescriptor(kind: "web", state: ["url": "https://example.org/a", "as": work.uuidString])
        let page = WebContent(descriptor: saved, settings: WebSettings())
        #expect(page.settings.profile == work && page.reloadedAs == OtherProfile(id: work))
        var home = WebSettings()
        home.profile = work
        let first = WebContent(descriptor: PaneDescriptor(kind: "web", state: ["as": "first"]), settings: home)
        #expect(first.settings.profile == nil && first.reloadedAs == OtherProfile(id: nil))
    }

    @Test func `a private page is not reloaded as a profile`() {
        var settings = WebSettings()
        settings.privacy = PagePrivacy(group: UUID())
        let page = WebContent(url: address, settings: settings)
        page.reload(as: work)
        #expect(page.reloadedAs == nil && page.settings.profile == nil)
    }
}
