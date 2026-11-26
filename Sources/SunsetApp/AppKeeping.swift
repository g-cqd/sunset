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

/// The app's side of what WebKit keeps between runs: each profile's store with what it keeps (the app's `web.keep`, or
/// the profile's own), and what is cleared before Sunset ends.
@MainActor enum AppKeeping {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
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
                    VariantStore.store(for: profile.isFirst ? nil : profile.id)
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

    /// At quit: every store cleared by what it keeps, every jar flushed then sealed; awaited at most `limit` (past it,
    /// the jars stay as WebKit writes them).
    static func clearAtQuit(limit: Duration = .seconds(5)) async {
        // WebKit's stores are the bundle's, the person's: a setup of a test or a second setup (its own folder) never
        // clears them.
        guard SunsetStore.shared.places.isDefault else { return }
        let every = stores()
        let all = every.filter { $0.keep != WebKeep() }
        await QuitDeadline.wait(limit: limit, runtime: runtime) { @MainActor in
            // The first quit that keeps the chosen sites keeps every site holding cookies then, in every profile: the
            // change signs no one out (3). Done here, when every profile's store is known.
            let choosing = all.filter { $0.keep.siteData == .keepChosen }.map(\.store)
            if !choosing.isEmpty { await WebKeeping.seedKept(from: choosing, visited: visitedHosts()) }
            for (store, keep, profile) in all { await WebKeeping.clear(store, keep: keep, profile: profile) }
            // Every cookie on disk now, then the jars made their owner's only: written at teardown instead, after Sunset
            // has gone, they were readable by every account. Then sealed: flushed, WebKit does not write them again.
            for (store, _, _) in every { await WebProcessControl.flushCookies(store.httpCookieStore) }
            WebKitFolders.tightenOwn()
            AppSealedData.sealJars()
            // Unload extensions before quieting/ending the network process so WebKit closes `WebExtensions/` databases
            // cleanly before `SiteStorage` seals them alongside site data (t137 / A4).
            ExtensionHosts.shared.unloadAll()
            // The sites' storage: the network process puts it to rest (nothing written after), then ends (it does not wake
            // to write again), then each file is sealed.
            for (store, _, _) in every { await WebProcessControl.quietNetwork(store) }
            for (store, _, _) in every { WebProcessControl.endNetwork(store) }
            AppSealedData.sealSiteStorage()
        }
    }
}
