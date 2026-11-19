package import Foundation

/// WebKit's cookie jars for Sunset, sealed at quit and opened at launch (task t114, design 0007, threat A4): a copy or a
/// backup of `~/Library` taken while Sunset is closed holds no session token in the clear. Probed (diary 2026-11-19-12):
/// flushed, then moved aside at quit, a jar is not written again by WebKit; put back before a store opens, its cookies are
/// read. Each sealed jar is bound to its place, so one cannot stand in for another store's.
///
/// While Sunset runs the jars are in the clear (0600): another program of the same user (A3) is not what this answers.
package struct CookieJars {
    package static let sealedExtension = "sealed"
    private let library: URL
    private let bundleID: String

    package init(library: URL, bundleID: String) {
        self.library = library
        self.bundleID = bundleID
    }

    /// What `open` did: jars put back, sealed ones dropped for a newer jar in the clear, sealed ones kept that do not open.
    package struct Opened: Equatable, Sendable {
        package var opened = 0
        package var newer = 0
        package var unreadable = 0
    }

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

    /// Seals each jar in the clear beside it (0600), checks the seal opens to the same bytes, then removes the clear jar.
    /// Returns how many were sealed. A jar whose seal cannot be written or checked stays in the clear.
    @discardableResult
    package func seal(with seal: Seal) -> Int {
        var sealedCount = 0
        for jar in clear() {
            guard let plain = try? Data(contentsOf: jar),
                let sealedData = try? seal.seal(plain, identity: identity(jar))
            else { continue }
            let place = sealedPlace(jar)
            guard (try? sealedData.write(to: place, options: [.atomic])) != nil,
                (try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: place.path)) != nil,
                let back = try? Data(contentsOf: place), (try? seal.open(back, identity: identity(jar))) == plain,
                (try? FileManager.default.removeItem(at: jar)) != nil
            else { continue }
            sealedCount += 1
        }
        return sealedCount
    }

    /// Puts each sealed jar back in the clear (0600) where none is, and removes the sealed one. A jar in the clear already is
    /// newer (written after the seal): it stays and the sealed one goes. A sealed jar that does not open (another key) is
    /// kept, never deleted.
    @discardableResult
    package func open(with seal: Seal) -> Opened {
        var outcome = Opened()
        for jar in places() {
            let place = sealedPlace(jar)
            guard FileManager.default.fileExists(atPath: place.path) else { continue }
            if FileManager.default.fileExists(atPath: jar.path) {
                try? FileManager.default.removeItem(at: place)
                outcome.newer += 1
                continue
            }
            guard let sealedData = try? Data(contentsOf: place),
                let plain = try? seal.open(sealedData, identity: identity(jar)),
                (try? plain.write(to: jar, options: [.atomic])) != nil
            else {
                outcome.unreadable += 1
                continue
            }
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: jar.path)
            try? FileManager.default.removeItem(at: place)
            outcome.opened += 1
        }
        return outcome
    }

    private func sealedPlace(_ jar: URL) -> URL {
        jar.appendingPathExtension(Self.sealedExtension)
    }

    /// The jar's place under the library: what its seal is bound to.
    private func identity(_ jar: URL) -> String {
        "cookie-jar:" + jar.path.replacingOccurrences(of: library.path, with: "")
    }
}
