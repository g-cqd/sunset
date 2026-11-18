import Foundation
import Testing

@testable import SunsetWeb

/// Roadmap 0022 W-d: Settings list every site that has something of its own (answers, the browser it is shown, blocking
/// paused, a zoom, its Space), and forget all of it at once.
@MainActor @Suite("Every site's own settings")
struct SiteSummaryTests {
    @Test func `each site is listed once with what it has; forgetting it takes all of it`() {
        let stores = SiteSummary.Stores(
            permissions: SitePermissions(),
            agents: SiteAgents(),
            pauses: BlockingPauses(),
            zoom: SiteZoom(),
            spaces: SiteSpaces.make(),
            hidden: HiddenElements.make()
        )
        let work = UUID()
        stores.permissions.set(.allow, .camera, for: "meet.example")
        stores.agents.set(.chrome, for: "meet.example")
        stores.pauses.set(true, for: "news.example")
        stores.zoom.set(1.25, for: "news.example", remember: false)
        stores.spaces.set(work, for: "tracker.example")
        stores.hidden.add("#promo", for: "tracker.example")
        let rows = SiteSummary.rows(stores) { $0 == work ? "Work" : nil }
        #expect(rows.map(\.host) == ["meet.example", "news.example", "tracker.example"])
        #expect(rows[0].parts == ["1 answer", "shown Chrome"])
        #expect(rows[1].parts == ["blocking paused", "zoom 125 %"])
        #expect(rows[2].parts == ["1 element hidden", "opens in Work"])
        SiteSummary.forget("meet.example", in: stores)
        SiteSummary.forget("news.example", in: stores)
        #expect(SiteSummary.rows(stores) { _ in nil }.map(\.host) == ["tracker.example"])
        SiteSummary.forget("tracker.example", in: stores)
        #expect(stores.hidden.rules.isEmpty && stores.spaces.rules.isEmpty)
    }

    /// ADR-0081: a site whose data is kept is listed so; Forget lets it go too.
    @Test func `a site kept is listed, and forgotten`() {
        let stores = SiteSummary.Stores(
            permissions: SitePermissions(),
            agents: SiteAgents(),
            pauses: BlockingPauses(),
            zoom: SiteZoom(),
            spaces: SiteSpaces.make(),
            hidden: HiddenElements.make(),
            kept: KeptSites()
        )
        stores.kept.set(true, for: "mail.example")
        #expect(SiteSummary.rows(stores) { _ in nil } == [.init(host: "mail.example", parts: ["data kept"])])
        SiteSummary.forget("mail.example", in: stores)
        #expect(!stores.kept.keeps("mail.example"))
    }
}
