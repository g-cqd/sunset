package import Foundation
package import SunsetWebModel

/// The hosts, one per profile, made the first time a page of the profile asks (roadmap 0109 B). With no folder set (tests that
/// do not ask for one; the app sets it when it starts), there are none and pages run no extension.
@MainActor package final class ExtensionHosts {
    package static let shared = ExtensionHosts()
    /// Where the profiles' folders are: `StoragePlaces.extensions`.
    package var root: URL?
    private var hosts: [UUID?: ExtensionHost] = [:]
    /// Installs what a store's page names into a profile: the app fetches the package and shows the prompt (roadmap 0109 E).
    package var installFromStore: (ExtensionStoreLink, UUID?) -> Void = { _, _ in }
    /// Sunset's windows and the one in front, as extensions see them: given by the app (roadmap 0109 B).
    package var windows: () -> [ExtensionWindow] = { [] }
    package var focused: () -> ExtensionWindow? = { nil }
    /// Installs the package at an address a page offered, into a profile: fetched, then the prompt (roadmap 0109 E).
    package var installPackage: (URL, UUID?) -> Void = { _, _ in }
    /// Opens a page for an extension (`tabs.create`, a link in its popup, its options page; the owner's note n67): at an
    /// address or blank, in a window of the profile (the one named, else the one in front), shown or not. Given by the app.
    package var openTab: (_ url: URL?, _ window: ExtensionWindow?, _ profile: UUID?, _ active: Bool) -> WebContent? = {
        _,
        _,
        _,
        _ in nil
    }

    package func host(for profile: UUID?) -> ExtensionHost? {
        guard let root else { return nil }
        if let host = hosts[profile] { return host }
        let host = ExtensionHost(root: root, profile: profile)
        hosts[profile] = host
        return host
    }

    /// Tells each host's extensions the windows opened and closed since, and the one in front (the app calls it as windows
    /// come, go and take the keyboard).
    package func sync() {
        let all = windows()
        let front = focused()
        for host in hosts.values { host.sync(all.filter { $0.profile == host.profile }, focused: front) }
    }

    /// No folder, no hosts (tests).
    package func reset() {
        root = nil
        hosts = [:]
        windows = { [] }
        focused = { nil }
        openTab = { _, _, _, _ in nil }
    }
}
