package import Foundation

/// What WebKit caches for sites stays out of backups (task t114, design 0007, threat A4): every cache folder under WebKit's
/// folder for Sunset is marked excluded, so Time Machine and backup tools that honour the mark leave it out:
/// - `CacheStorage`, the Cache API, which sites fill and refill (1.2 GB of 1.7 GB on the owner's Mac);
/// - `NetworkCache` and `MediaCache`, which each profile's store keeps beside its data, not in `~/Library/Caches` (the
///   default store's network cache, which Time Machine leaves out by itself: measured).
/// What sites keep for the person (cookies, IndexedDB, local storage) stays in.
/// Run at launch: a store or an origin made since has a folder of its own.
extension WebKitFolders {
    static let cacheFolders: Set<String> = ["CacheStorage", "NetworkCache", "MediaCache"]

    /// The same for this app's stores (`~/Library/WebKit/<bundle identifier>`), off the main thread's way at launch.
    package static func excludeOwnCaches() {
        guard let id = Bundle.main.bundleIdentifier,
            let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        else { return }
        excludeCaches(under: library.appending(path: "WebKit/\(id)"))
    }

    /// Marks each `CacheStorage` folder under `root` excluded from backups; how many were marked now.
    /// - Complexity: O(the folders under `root`, down to the first `CacheStorage` of each branch).
    @discardableResult
    package static func excludeCaches(under root: URL) -> Int {
        guard
            let walk = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .isExcludedFromBackupKey],
                options: [.skipsHiddenFiles]
            )
        else { return 0 }
        var marked = 0
        for case var url as URL in walk {
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isExcludedFromBackupKey])
            guard values?.isDirectory == true else { continue }
            guard cacheFolders.contains(url.lastPathComponent) else { continue }
            walk.skipDescendants()
            guard values?.isExcludedFromBackup != true else { continue }
            var excluded = URLResourceValues()
            excluded.isExcludedFromBackup = true
            if (try? url.setResourceValues(excluded)) != nil { marked += 1 }
        }
        return marked
    }
}
