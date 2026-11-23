import Foundation
import SunsetConfig
import SunsetWeb
import WebKit

/// What clearing removes: the history's pages, WebKit's website data and the site zoom levels, from `date` on.
@MainActor enum WebClearing {
    static func clear(since date: Date, history: Bool, websiteData: Bool, siteZoom: Bool) {
        if history {
            AppHistory.shared?.clear(since: date)
            DownloadCenter.shared.clear()
            // The sites' icons say where one went.
            FaviconStore.shared.forgetAll()
        }
        if siteZoom { SiteZoom.shared.clearAll() }
        if websiteData {
            VariantStore.store(for: nil)
                .removeData(
                    ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                    modifiedSince: date
                ) {}
        }
        if !history { HistoryChanges.shared.bump() }
    }

    /// At quit, by `web.clearHistoryOnQuit`, and what WebKit keeps by `web.keep` and each profile's (`AppKeeping`), before
    /// the app ends.
    static func clearAtQuit() async {
        let web = AppConfiguration.shared.configuration.web
        if web.clearHistoryOnQuit {
            AppHistory.shared?.clear(since: .distantPast)
            FaviconStore.shared.forgetAll()
        }
        // What WebKit keeps, by each profile.
        await AppKeeping.clearAtQuit()
    }
}
