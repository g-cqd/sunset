import Foundation
import SunsetAppCore
import SunsetStorage

/// WebKit's cookie jars for this app sealed at quit, opened at launch (task t114, ADR-0103): never for a test's or a second
/// setup's run (they would touch the person's jars), nor without the store's key (nothing to seal with: the jars stay as
/// WebKit wrote them).
@MainActor
enum AppCookieJars {
    private static var jars: CookieJars? {
        guard SunsetStore.shared.places.isDefault, let id = Bundle.main.bundleIdentifier,
            let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        else { return nil }
        return CookieJars(library: library, bundleID: id)
    }

    /// Before any store opens: each sealed jar put back.
    static func openAtLaunch() {
        guard let jars, let seal = SunsetStore.shared.seal(.cookies) else { return }
        jars.open(with: seal)
    }

    /// After every store's cookies are flushed: each jar sealed.
    static func sealAtQuit() {
        guard let jars, let seal = SunsetStore.shared.seal(.cookies) else { return }
        jars.seal(with: seal)
    }
}
