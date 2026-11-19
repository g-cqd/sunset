package import Foundation
package import WebKit

/// Clears what is not kept from WebKit's stores (ADR-0081), and fills the kept list once.
@MainActor
package enum WebKeeping {
    /// The registrable domains holding cookies in `store`.
    package static func sitesWithCookies(in store: WKWebsiteDataStore) async -> [String] {
        await store.dataRecords(ofTypes: [WKWebsiteDataTypeCookies]).map(\.displayName)
    }

    /// The first run that keeps the chosen sites: every site holding cookies in `stores` that was visited (`visited`,
    /// hosts of the history) is kept, so that no sign-in is lost; a site only ever loaded under others (a tracker) is not.
    /// With no history to tell, every site holding cookies is kept.
    package static func seedKept(from stores: [WKWebsiteDataStore], visited: [String], kept: KeptSites = .shared) async
    {
        var sites: [String] = []
        for store in stores { sites += await sitesWithCookies(in: store) }
        let first = visited.isEmpty ? sites : sites.filter { WebKeepPlan.isKept($0, by: visited) }
        kept.seedOnce(with: Array(Set(first)).sorted())
    }

    /// Clears `store` by `keep`: what is cleared everywhere, then the data of the sites not kept.
    /// `profile`: the store's, whose own kept sites count with all profiles' (roadmap 0050 E).
    package static func clear(
        _ store: WKWebsiteDataStore,
        keep: WebKeep,
        profile: UUID? = nil,
        kept: KeptSites = .shared
    ) async {
        let records = await store.dataRecords(ofTypes: WebKeepPlan.siteDataTypes)
        let plan = WebKeepPlan.make(keep, records: records.map(\.displayName), kept: kept.hosts(profile: profile))
        if !plan.everywhere.isEmpty { await store.removeData(ofTypes: plan.everywhere, modifiedSince: .distantPast) }
        let cleared = Set(plan.sites)
        let gone = records.filter { cleared.contains($0.displayName) }
        if !gone.isEmpty { await store.removeData(ofTypes: plan.siteTypes, for: gone) }
    }
}
