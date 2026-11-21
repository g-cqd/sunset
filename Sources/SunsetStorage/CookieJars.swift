package import Foundation

/// WebKit's cookie jars for Sunset, sealed at quit and opened at launch (task t114, design 0007, threat A4): a copy or a
/// backup of `~/Library` taken while Sunset is closed holds no session token in the clear. Probed (diary 2026-11-19-12):
/// flushed, then moved aside at quit, a jar is not written again by WebKit; put back before a store opens, its cookies are
/// read. Each sealed jar is bound to its place, so one cannot stand in for another store's.
///
/// While Sunset runs the jars are in the clear (0600): another program of the same user (A3) is not what this answers.
package struct CookieJars {
    package static let sealedExtension = SealedFiles.sealedExtension
    private let library: URL
    private let bundleID: String

    package init(library: URL, bundleID: String) {
        self.library = library
        self.bundleID = bundleID
    }

    package typealias Opened = SealedFiles.Opened

    /// The default store's jar and every profile store's.
    /// - Complexity: O(the profile stores).
    package func places() -> [URL] {
        let stores = library.appending(path: "WebKit/\(bundleID)/WebsiteDataStore")
        let profiles = (try? FileManager.default.contentsOfDirectory(at: stores, includingPropertiesForKeys: nil)) ?? []
        return [library.appending(path: "HTTPStorages/\(bundleID).binarycookies")]
            + profiles.map { $0.appending(path: "Cookies/Cookies.binarycookies") }
    }

    /// The jars in the clear now.
    package func clear() -> [URL] {
        places().filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// The sealed jars now.
    package func sealed() -> [URL] {
        places().map(sealedPlace).filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// Seals each jar in the clear beside it (`SealedFiles.seal`); how many were sealed. One whose seal cannot be written or
    /// checked stays in the clear.
    @discardableResult
    package func seal(with seal: Seal) -> Int {
        clear()
            .reduce(0) { count, jar in SealedFiles.seal(jar, identity: identity(jar), with: seal) ? count + 1 : count }
    }

    /// Puts each sealed jar back (`SealedFiles.open`): a jar in the clear already is newer and stays; a seal that does not
    /// open is kept.
    @discardableResult
    package func open(with seal: Seal) -> Opened {
        var outcome = Opened()
        for place in sealed() { SealedFiles.open(place, identity: identity, with: seal, into: &outcome) }
        return outcome
    }

    private func sealedPlace(_ jar: URL) -> URL {
        SealedFiles.sealedPlace(jar)
    }

    /// The jar's place under the library: what its seal is bound to.
    private func identity(_ jar: URL) -> String {
        "cookie-jar:" + jar.path.replacingOccurrences(of: library.path, with: "")
    }
}
