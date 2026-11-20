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
    /// Installs the package at an address a page offered, into a profile: fetched, then the prompt (roadmap 0109 E).
    package var installPackage: (URL, UUID?) -> Void = { _, _ in }

    package func host(for profile: UUID?) -> ExtensionHost? {
        guard let root else { return nil }
        if let host = hosts[profile] { return host }
        let host = ExtensionHost(root: root, profile: profile)
        hosts[profile] = host
        return host
    }

    /// No folder, no hosts (tests).
    package func reset() {
        root = nil
        hosts = [:]
    }
}
