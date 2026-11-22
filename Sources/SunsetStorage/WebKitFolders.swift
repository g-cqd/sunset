package import Foundation

/// What WebKit keeps for Sunset beside Sunset's own store (docs/research/storage-audit-webkit-data-2026-11-18.md): its
/// caches, its website data, its cookie jar. WebKit makes them readable by every account (0755, 0644); Sunset makes them its
/// owner's only, at launch and at quit. `~/Library` is already its owner's only: this holds when a copy or a backup keeps
/// the modes, or a parent is opened.
package enum WebKitFolders {
    /// The folders and files of the app `bundleID` under `library` (`~/Library`).
    package static func places(library: URL, bundleID: String) -> (folders: [URL], files: [URL]) {
        (
            ["Caches", "WebKit", "HTTPStorages"].map { library.appending(path: "\($0)/\(bundleID)") },
            [library.appending(path: "HTTPStorages/\(bundleID).binarycookies")]
        )
    }

    /// Makes every one that exists its owner's only: folders 0700, files 0600. Returns how many it changed.
    @discardableResult
    package static func tighten(library: URL, bundleID: String) -> Int {
        let files = FileManager.default
        let (folders, jars) = places(library: library, bundleID: bundleID)
        var changed = 0
        for (url, mode) in folders.map({ ($0, 0o700) }) + jars.map({ ($0, 0o600) }) {
            guard let now = (try? files.attributesOfItem(atPath: url.path))?[.posixPermissions] as? Int, now != mode
            else { continue }
            if (try? files.setAttributes([.posixPermissions: mode], ofItemAtPath: url.path)) != nil { changed += 1 }
        }
        return changed
    }

    /// The same for this app, in the person's Library.
    package static func tightenOwn() {
        guard let id = Bundle.main.bundleIdentifier,
            let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        else { return }
        tighten(library: library, bundleID: id)
    }
}
