import Testing

@testable import SunsetWeb

/// ADR-0081 (roadmap 0051 H): what Sunset clears at quit from WebKit's stores.
@Suite("What is cleared at quit") struct WebKeepPlanTests {
    @Test func `the types are WebKit's, each in one kind, none left out`() {
        let kinds = [WebKeepPlan.cacheTypes, WebKeepPlan.traceTypes, WebKeepPlan.siteDataTypes]
        #expect(kinds.allSatisfy { !$0.isEmpty })
        #expect(
            kinds[0].isDisjoint(with: kinds[1]) && kinds[1].isDisjoint(with: kinds[2])
                && kinds[0].isDisjoint(with: kinds[2])
        )
        // Every type WebKit has (probed, 2026-11-18), but the Screen Time and search field ones, which are not the pages'.
        #expect(kinds.reduce(Set<String>()) { $0.union($1) }.count == 19)
        #expect(WebKeepPlan.cacheTypes.contains("WKWebsiteDataTypeDiskCache"))
        #expect(WebKeepPlan.traceTypes.contains("_WKWebsiteDataTypeHSTSCache"))
        #expect(WebKeepPlan.siteDataTypes.contains("WKWebsiteDataTypeCookies"))
    }

    @Test func `kept is kept: nothing cleared`() {
        let plan = WebKeepPlan.make(.init(), records: ["example.org"], kept: [])
        #expect(plan.everywhere.isEmpty && plan.sites.isEmpty)
    }

    @Test func `each kind cleared on quit is cleared everywhere`() {
        let all = WebKeepPlan.make(
            .init(clearsCache: true, clearsTraces: true, siteData: .clearOnQuit),
            records: ["a.org"],
            kept: ["a.org"]
        )
        #expect(all.everywhere == WebKeepPlan.cacheTypes.union(WebKeepPlan.traceTypes).union(WebKeepPlan.siteDataTypes))
        #expect(all.sites.isEmpty, "clearing everything keeps no site")
        let cache = WebKeepPlan.make(.init(clearsCache: true), records: [], kept: [])
        #expect(cache.everywhere == WebKeepPlan.cacheTypes)
    }

    @Test func `kept for the sites chosen clears the others' data only`() {
        let plan = WebKeepPlan.make(
            .init(siteData: .keepChosen),
            records: ["example.org", "tracker.example", "mail.example.com", "news.example"],
            kept: ["app.example.org", "example.com"]
        )
        #expect(plan.everywhere.isEmpty)
        #expect(plan.sites == ["tracker.example", "news.example"])
        #expect(plan.siteTypes == WebKeepPlan.siteDataTypes)
    }

    @Test func `a site is kept by itself, a subdomain of it, or what it is under, never by a mere suffix`() {
        #expect(WebKeepPlan.isKept("example.org", by: ["example.org"]))
        #expect(WebKeepPlan.isKept("example.org", by: ["app.example.org"]))
        #expect(WebKeepPlan.isKept("app.example.org", by: ["example.org"]))
        #expect(!WebKeepPlan.isKept("example.org", by: ["badexample.org"]))
        #expect(!WebKeepPlan.isKept("badexample.org", by: ["example.org"]))
    }
}
