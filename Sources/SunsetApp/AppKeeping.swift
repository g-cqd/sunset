import Foundation
import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetStorage
import SunsetWeb
import WebKit

/// The app's side of what WebKit keeps between runs (ADR-0081): each profile's store with what it keeps (the app's
/// `web.keep`, or the profile's own), and what is cleared before Sunset ends.
@MainActor enum AppKeeping {
    /// What `profile` keeps: its own choices over the app's.
    static func keep(for profile: Profile) -> Configuration.Web.Keep {
        AppConfiguration.shared.configuration.web.keep.overriding(
            cache: profile.keep.cache,
            traces: profile.keep.traces,
            siteData: profile.keep.siteData
        )
    }

    /// Each profile's store (the first's is WebKit's default one) and what it keeps. A private window's store is not
    /// persistent and is not among them.
    static func stores() -> [(store: WKWebsiteDataStore, keep: WebKeep)] {
        AppSpaces.all.profiles.profiles.map(\.profile)
            .map { profile in
                let store =
                    profile.isFirst ? WKWebsiteDataStore.default() : WKWebsiteDataStore(forIdentifier: profile.id)
                return (store, web(keep(for: profile)))
            }
    }

    static func web(_ keep: Configuration.Web.Keep) -> WebKeep {
        let siteData: WebKeep.SiteData =
            switch keep.siteData {
                case .keep: .keep
                case .keepChosen: .keepChosen
                case .clearOnQuit: .clearOnQuit
            }
        return WebKeep(
            clearsCache: keep.cache == .clearOnQuit,
            clearsTraces: keep.traces == .clearOnQuit,
            siteData: siteData
        )
    }

    /// At launch: the kept list, from the sealed store.
    static func start() {
        KeptSites.shared.table = AppStorage.shared.table("kept-sites")
        KeptSites.shared.marks = AppStorage.shared.table("kept-sites-marks")
        KeptSites.shared.applies = { id in
            let profile = AppSpaces.all.profiles.profiles.map(\.profile).first { $0.id == (id ?? Profile.firstID) }
            return keep(for: profile ?? .first).siteData == .keepChosen
        }
    }

    /// The hosts of the pages in the history.
    private static func visitedHosts() -> [String] {
        let entries = AppHistory.shared?.entries(limit: .max) ?? []
        return Array(Set(entries.compactMap { URL(string: $0.url)?.host() }))
    }

    /// At quit: every store cleared by what it keeps; the quit waits for WebKit, at most `limit` seconds.
    static func clearAtQuit(limit: TimeInterval = 5) {
        // WebKit's stores are the bundle's, the person's: a setup of a test or a second setup (its own folder) never
        // clears them.
        guard AppStorage.shared.places.isDefault else { return }
        let all = stores().filter { $0.keep != WebKeep() }
        guard !all.isEmpty else { return }
        var done = false
        Task {
            // The first quit that keeps the chosen sites keeps every site holding cookies then, in every profile: the
            // change signs no one out (ADR-0081, 3). Done here, when every profile's store is known.
            let choosing = all.filter { $0.keep.siteData == .keepChosen }.map(\.store)
            if !choosing.isEmpty { await WebKeeping.seedKept(from: choosing, visited: visitedHosts()) }
            for (store, keep) in all { await WebKeeping.clear(store, keep: keep) }
            done = true
        }
        let end = Date().addingTimeInterval(limit)
        while !done, Date() < end { RunLoop.main.run(until: Date().addingTimeInterval(0.05)) }
    }
}
