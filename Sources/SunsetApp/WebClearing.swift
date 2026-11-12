import Foundation
import SunsetConfig
import SunsetWeb
import WebKit

/// What clearing removes (web step e): the history's pages, WebKit's website data and the site zoom levels, from `date` on.
@MainActor enum WebClearing {
    static func clear(since date: Date, history: Bool, websiteData: Bool, siteZoom: Bool) {
        if history { AppHistory.shared?.clear(since: date) }
        if siteZoom { SiteZoom.shared.clearAll() }
        if websiteData {
            WKWebsiteDataStore.default()
                .removeData(
                    ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                    modifiedSince: date
                ) {}
        }
        if !history { HistoryChanges.shared.bump() }
    }

    /// At quit, by `web.clearHistoryOnQuit` and `web.clearWebsiteDataOnQuit`. Website data is removed before the app ends (it waits for WebKit,
    /// up to two seconds).
    static func clearAtQuit() {
        let web = AppConfiguration.shared.configuration.web
        if web.clearHistoryOnQuit { AppHistory.shared?.clear(since: .distantPast) }
        guard web.clearWebsiteDataOnQuit else { return }
        var done = false
        WKWebsiteDataStore.default()
            .removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {
                done = true
            }
        let limit = Date().addingTimeInterval(2)
        while !done, Date() < limit { RunLoop.main.run(until: Date().addingTimeInterval(0.05)) }
    }
}
