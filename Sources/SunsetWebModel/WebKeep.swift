/// What WebKit keeps between runs, as `web.keep` says it; SunsetWeb does not read the configuration.
package struct WebKeep: Equatable, Sendable {
    package enum SiteData: Sendable { case keep, keepChosen, clearOnQuit }

    package var clearsCache: Bool
    package var clearsTraces: Bool
    package var siteData: SiteData

    package init(clearsCache: Bool = false, clearsTraces: Bool = false, siteData: SiteData = .keep) {
        self.clearsCache = clearsCache
        self.clearsTraces = clearsTraces
        self.siteData = siteData
    }
}
