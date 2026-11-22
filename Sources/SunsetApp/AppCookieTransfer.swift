import Foundation
import SunsetAppCore
import SunsetRuntime
import SunsetShellModel
import SunsetStorage
import WebKit

/// File ▸ Bring Cookies from Sunset (roadmap 0112 E, ADR-0114): Sunset WebKit reads Sunset's cookie jars (sealed with the
/// key both builds share, or in the clear while Sunset runs) and sets each cookie that has not expired in the same profile's
/// store of its own WebKit. One way, on the person's request; WebKit's own files are never shared.
@MainActor
enum AppCookieTransfer {
    /// Sunset's identifier: whose jars are read.
    private static let sunset = "studio.aemi.sunset"

    /// Offered in Sunset WebKit only, on the person's own setup.
    static var isOffered: Bool {
        StoragePlaces.current.former != nil
    }

    static func bring() {
        guard isOffered, let seal = SunsetStore.shared.seal(.cookies),
            let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        else { return }
        let read = CookieJars(library: library, bundleID: sunset).read(with: seal)
        Runtime.live.task { @MainActor in
            let now = Runtime.live.now()
            var brought = 0
            for (store, _, profile) in AppKeeping.stores() {
                for cookie in read.stores[profile] ?? [] where cookie.expires > now {
                    guard let made = HTTPCookie(properties: cookie.httpProperties) else { continue }
                    await store.httpCookieStore.setCookie(made)
                    brought += 1
                }
            }
            tell(brought: brought, unreadable: read.unreadable)
        }
    }

    private static func tell(brought: Int, unreadable: Int) {
        var message =
            brought == 0
            ? "Sunset has no cookies to bring for these profiles."
            : "Sites you were signed in to in Sunset should know you here too. Each site may still ask again."
        if unreadable > 0 {
            message += " \(unreadable) of Sunset\u{2019}s cookie files could not be read."
        }
        let alert = SunsetAlert(
            title: brought == 1 ? "1 cookie brought from Sunset" : "\(brought) cookies brought from Sunset",
            message: message,
            buttons: [.plain("OK")],
            defaultButton: 0
        )
        SunsetAlerts.show(alert) { _ in }
    }
}
