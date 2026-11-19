import Foundation
import SunsetPane
import SunsetShell
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

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

    private static let thirdID = UUID()
    private var profiles: [(id: UUID?, name: String)] {
        [(nil, "Personal"), (work, "Work"), (Self.thirdID, "Third")]
    }

    /// The owner, 2026-11-19: the menu said "(its Space's)" beside a profile that was not the Space's. A page never reloaded
    /// has no home kept, and the first profile's id (nil) matched that absence.
    @Test func `only the profile of the page's own Space is marked as its Space's`() {
        var home = WebSettings()
        home.profile = work
        let page = WebContent(url: address, settings: home)
        #expect(
            page.reloadAsAction(among: profiles)?.children.map(\.title) == ["Personal", "Third"],
            "never reloaded: its Space's is the one it is in"
        )
        page.reload(as: Self.thirdID)
        #expect(
            page.reloadAsAction(among: profiles)?.children.map(\.title) == ["Personal", "Work (its Space\u{2019}s)"]
        )
        let first = WebContent(url: address, settings: WebSettings())
        #expect(first.reloadAsAction(among: profiles)?.children.map(\.title) == ["Work", "Third"])
        first.reload(as: work)
        #expect(
            first.reloadAsAction(among: profiles)?.children.map(\.title) == ["Personal (its Space\u{2019}s)", "Third"]
        )
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
