import Foundation
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// Roadmap 0050 E (not done: "elements hidden: one compiled list for every page"): a profile hides elements for itself; all
/// profiles' apply where it set none for a site. Each profile with its own gets a list of its own.
@MainActor @Suite("Hidden elements per profile")
struct HiddenElementsProfileTests {
    private let work = UUID()

    @Test func `a profile's own hide replace all profiles' site by site; the others come through`() {
        let hidden = HiddenElements.make()
        hidden.add(".ad", for: "news.example")
        hidden.add(".cookie", for: "shop.example")
        hidden.add(".banner", for: "news.example", profile: work)
        #expect(hidden.selectors(for: "news.example") == [".ad"], "all profiles' unchanged")
        #expect(hidden.selectors(for: "news.example", profile: work) == [".banner"])
        #expect(hidden.selectors(for: "shop.example", profile: work) == [".cookie"], "where it set none: all profiles'")
        #expect(hidden.profilesWithOwn == [work])
        let sites = ContentBlocker.hiddenSites(hidden, profile: work).map { "\($0.host) \($0.selectors)" }
        #expect(sites == ["news.example [\".banner\"]", "shop.example [\".cookie\"]"])
        #expect(ContentBlocker.hiddenSites(hidden, profile: nil).map(\.host) == ["news.example", "shop.example"])
        hidden.remove(".banner", for: "news.example", profile: work)
        #expect(hidden.profilesWithOwn.isEmpty)
    }
}

extension HiddenElementsProfileTests {
    @Test func `Each site lists and resets a profile's own hidden elements`() {
        let stores = SiteSummary.Stores(
            permissions: SitePermissions(),
            agents: SiteAgents(),
            pauses: BlockingPauses(),
            zoom: SiteZoom(),
            spaces: SiteSpaces.make(),
            hidden: HiddenElements.make(),
            kept: KeptSites()
        )
        stores.hidden.add(".banner", for: "news.example", profile: work)
        #expect(SiteSummary.rows(stores) { _ in nil }.isEmpty, "not all profiles'")
        #expect(SiteSummary.rows(stores, profile: work) { _ in nil }.map(\.host) == ["news.example"])
        SiteSummary.reset(.hidden, of: "news.example", in: stores, profile: work)
        #expect(stores.hidden.rules(profile: work).isEmpty)
    }
}
