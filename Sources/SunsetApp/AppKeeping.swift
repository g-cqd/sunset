import Foundation
import SunsetAppCore
import SunsetConfig
import SunsetPane
import SunsetPrivate
import SunsetRuntime
import SunsetShell
import SunsetStorage
import SunsetWeb
import WebKit

/// The app's side of what WebKit keeps between runs (ADR-0081): each profile's store with what it keeps (the app's
/// `web.keep`, or the profile's own), and what is cleared before Sunset ends.
@MainActor enum AppKeeping {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    static var runtime = Runtime.live

    /// What `profile` keeps: its own choices over the app's.
    static func keep(for profile: Profile) -> Configuration.Web.Keep {
        .of(profile, app: AppConfiguration.shared.configuration)
    }

    /// Each profile's store (the first's is WebKit's default one) and what it keeps. A private window's store is not
    /// persistent and is not among them.
    static func stores() -> [(store: WKWebsiteDataStore, keep: WebKeep, profile: UUID?)] {
        AppSpaces.all.profiles.profiles.map(\.profile)
            .map { profile in
                let store =
                    profile.isFirst ? WKWebsiteDataStore.default() : WKWebsiteDataStore(forIdentifier: profile.id)
                return (store, web(keep(for: profile)), profile.isFirst ? nil : profile.id)
            }
    }

    static func web(_ keep: Configuration.Web.Keep) -> WebKeep {
        keep.webKeep
    }

    /// At launch: the kept list, from the sealed store.
    static func start() {
        AppShare.start()
        KeptSites.shared.table = SunsetStore.shared.table("kept-sites")
        KeptSites.shared.marks = SunsetStore.shared.table("kept-sites-marks")
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

    /// At quit: every store cleared by what it keeps, every jar flushed then sealed (task t114); the quit waits for WebKit,
    /// at most `limit` seconds (past it, the jars stay as WebKit writes them).
    static func clearAtQuit(limit: TimeInterval = 5) {
        // WebKit's stores are the bundle's, the person's: a setup of a test or a second setup (its own folder) never
        // clears them.
        guard SunsetStore.shared.places.isDefault else { return }
        let every = stores()
        let all = every.filter { $0.keep != WebKeep() }
        var done = false
        runtime.task {
            // The first quit that keeps the chosen sites keeps every site holding cookies then, in every profile: the
            // change signs no one out (ADR-0081, 3). Done here, when every profile's store is known.
            let choosing = all.filter { $0.keep.siteData == .keepChosen }.map(\.store)
            if !choosing.isEmpty { await WebKeeping.seedKept(from: choosing, visited: visitedHosts()) }
            for (store, keep, profile) in all { await WebKeeping.clear(store, keep: keep, profile: profile) }
            // Every cookie on disk now, then the jars made their owner's only: written at teardown instead, after Sunset
            // has gone, they were readable by every account (roadmap 0051 G). Then sealed: flushed, WebKit does not write
            // them again (diary 2026-11-19-12).
            for (store, _, _) in every { await WebProcessControl.flushCookies(store.httpCookieStore) }
            WebKitFolders.tightenOwn()
            AppCookieJars.sealAtQuit()
            done = true
        }
        // A deadline on the monotonic clock, not the wall clock (which may jump).
        let end = runtime.uptime() + .seconds(limit)
        while !done, runtime.uptime() < end {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        }
    }
}
