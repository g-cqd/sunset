package import Foundation

/// What sites keep for the person in WebKit's stores for Sunset, sealed at quit and opened at launch (threat model A4):
/// IndexedDB, local storage, service workers, and what tells which sites were seen (tracking prevention's statistics,
/// HSTS). A copy or a backup of `~/Library` taken while Sunset is closed holds none of it in the clear. Caches are not
/// here: they stay out of backups (`excludeCaches`). Each file is sealed beside itself, bound to its place; at launch a
/// file in the clear beside its seal is newer and stays.
///
/// While Sunset runs they are in the clear (A3 is not what this answers); a crash leaves them in the clear until the next
/// quit.
package struct SiteStorage {
    /// The folders whose files are sealed, wherever WebKit keeps them (per store, per origin, and per extension).
    package static let folders: Set<String> = Set(
        "IndexedDB LocalStorage ServiceWorkers ResourceLoadStatistics HSTS WebExtensions Origins IsolatedSites AlternativeServices EnhancedSecurity"
            .split(separator: " ")
            .map(String.init)
    )
    private let root: URL
    /// What a file's place is read from: its path after this (the same however the path to the library is written, as
    /// `/var` or `/private/var`).
    private let marker: String

    package init(library: URL, bundleID: String) {
        root = library.appending(path: "WebKit/\(bundleID)")
        marker = "/WebKit/\(bundleID)/"
    }

    /// The files in the clear now, and the sealed ones.
    /// - Complexity: O(the files under WebKit's folder for Sunset, skipping the caches' folders).
    package func files() -> (clear: [URL], sealed: [URL]) {
        guard
            let walk = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: []
            )
        else { return ([], []) }
        var clear: [URL] = []
        var sealed: [URL] = []
        for case let url as URL in walk {
            let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
            if values?.isDirectory == true {
                if WebKitFolders.cacheFolders.contains(url.lastPathComponent) { walk.skipDescendants() }
                continue
            }
            guard values?.isRegularFile == true,
                url.lastPathComponent != ".DS_Store",
                url.pathComponents.dropLast().contains(where: Self.folders.contains)
            else { continue }
            if url.pathExtension == SealedFiles.sealedExtension { sealed.append(url) } else { clear.append(url) }
        }
        return (clear, sealed)
    }

    /// Seals each file in the clear; how many were sealed. One whose seal cannot be written or checked stays in the clear.
    @discardableResult
    package func seal(with seal: Seal) -> Int {
        files().clear
            .reduce(0) { count, file in
                SealedFiles.seal(file, identity: identity(file), with: seal) ? count + 1 : count
            }
    }

    /// Puts each sealed file back (`SealedFiles.open`).
    @discardableResult
    package func open(with seal: Seal) -> SealedFiles.Opened {
        var outcome = SealedFiles.Opened()
        for place in files().sealed { SealedFiles.open(place, identity: identity, with: seal, into: &outcome) }
        return outcome
    }

    /// The file's place under WebKit's folder for the app: what its seal is bound to.
    private func identity(_ file: URL) -> String {
        let path = file.path
        let place = path.range(of: marker, options: .backwards).map { String(path[$0.upperBound...]) } ?? path
        return "site-data:" + place
    }
}
