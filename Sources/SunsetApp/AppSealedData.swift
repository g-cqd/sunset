import Foundation
import SunsetAppCore
import SunsetStorage

/// What WebKit keeps for the person, sealed while Sunset is closed and opened at launch (threat model A4: a backup or a
/// copy of `~/Library`): the cookie jars (`CookieJars`) and what sites store (`SiteStorage`). Never for a test's or a second
/// setup's run (they would touch the person's data), nor without the store's key.
@MainActor
enum AppSealedData {
    private static var library: (URL, String)? {
        guard SunsetStore.shared.places.isDefault, let id = Bundle.main.bundleIdentifier,
            let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        else { return nil }
        return (library, id)
    }

    /// Before any store opens: each sealed file put back.
    static func openAtLaunch() {
        guard let (library, id) = library else { return }
        if let seal = SunsetStore.shared.seal(.cookies) { CookieJars(library: library, bundleID: id).open(with: seal) }
        if let seal = SunsetStore.shared.seal(.siteData) {
            SiteStorage(library: library, bundleID: id).open(with: seal)
        }
    }

    /// After every store's cookies are flushed: each jar sealed.
    static func sealJars() {
        guard let (library, id) = library, let seal = SunsetStore.shared.seal(.cookies) else { return }
        CookieJars(library: library, bundleID: id).seal(with: seal)
    }

    /// After the network process has put its storage to rest and ended: each site's file sealed.
    static func sealSiteStorage() {
        guard let (library, id) = library, let seal = SunsetStore.shared.seal(.siteData) else { return }
        SiteStorage(library: library, bundleID: id).seal(with: seal)
    }
}
