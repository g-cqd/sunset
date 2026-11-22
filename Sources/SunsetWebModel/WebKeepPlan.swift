/// What to clear when Sunset quits, from `web.keep` and the sites kept: WebKit's data types by name, removed from a
/// whole store, and the sites (WebKit's records, by their registrable domain) whose own data is removed.
package struct WebKeepPlan: Equatable, Sendable {
    /// Removed from the whole store.
    package var everywhere: Set<String>
    /// Removed from these records only (their `displayName`).
    package var sites: [String]
    /// What is removed from them.
    package var siteTypes: Set<String>

    /// What was fetched: pages, files, their addresses (WebKit's names, probed 2026-11-18).
    package static let cacheTypes: Set<String> = [
        "WKWebsiteDataTypeDiskCache", "WKWebsiteDataTypeMemoryCache", "WKWebsiteDataTypeFetchCache"
    ]
    /// What says where one went and when, without being a site's data: the sites that asked for HTTPS only, the
    /// interaction log, HTTP/3 records, click measurements (WebKit's private names).
    package static let traceTypes: Set<String> = [
        "_WKWebsiteDataTypeHSTSCache", "_WKWebsiteDataTypeResourceLoadStatistics",
        "_WKWebsiteDataTypeAlternativeServices",
        "_WKWebsiteDataTypeAdClickAttributions", "_WKWebsiteDataTypePrivateClickMeasurements",
        "_WKWebsiteDataTypeEnhancedSecurityRecord"
    ]
    /// What a site keeps: cookies (sign-ins), its storage, its workers, its keys and salts, credentials.
    package static let siteDataTypes: Set<String> = [
        "WKWebsiteDataTypeCookies", "WKWebsiteDataTypeLocalStorage", "WKWebsiteDataTypeSessionStorage",
        "WKWebsiteDataTypeIndexedDBDatabases", "WKWebsiteDataTypeWebSQLDatabases",
        "WKWebsiteDataTypeServiceWorkerRegistrations", "WKWebsiteDataTypeFileSystem", "WKWebsiteDataTypeMediaKeys",
        "WKWebsiteDataTypeHashSalt", "_WKWebsiteDataTypeCredentials"
    ]

    /// The plan for `keep`, the store's records being `records` (registrable domains), `kept` the sites kept (hosts).
    package static func make(_ keep: WebKeep, records: [String], kept: [String]) -> Self {
        var everywhere: Set<String> = []
        if keep.clearsCache { everywhere.formUnion(cacheTypes) }
        if keep.clearsTraces { everywhere.formUnion(traceTypes) }
        switch keep.siteData {
            case .keep:
                return Self(everywhere: everywhere, sites: [], siteTypes: [])
            case .clearOnQuit:
                return Self(everywhere: everywhere.union(siteDataTypes), sites: [], siteTypes: [])
            case .keepChosen:
                let cleared = records.filter { !isKept($0, by: kept) }
                return Self(everywhere: everywhere, sites: cleared, siteTypes: cleared.isEmpty ? [] : siteDataTypes)
        }
    }

    /// Whether a record (a registrable domain) is of a site kept: the same, a subdomain of it, or what it is under.
    package static func isKept(_ record: String, by kept: [String]) -> Bool {
        let record = record.lowercased()
        return kept.contains { site in
            let site = site.lowercased()
            return site == record || site.hasSuffix("." + record) || record.hasSuffix("." + site)
        }
    }
}
