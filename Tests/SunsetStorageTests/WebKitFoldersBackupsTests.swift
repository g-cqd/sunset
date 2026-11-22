import Foundation
import Testing

@testable import SunsetStorage

/// Design 0007, threat A4: what WebKit caches for sites (the Cache API's `CacheStorage`, 1.2 GB of Sunset's 1.7 GB of
/// website data on one Mac) is left out of backups; what sites keep for the person (IndexedDB, local storage) stays in.
/// The network cache is in `~/Library/Caches`, which Time Machine leaves out by itself (measured).
@Suite("Website data: caches out of backups")
struct WebKitFoldersBackupsTests {
    @Test
    func `every cache folder under a store is excluded (the Cache API's, the network's, media's), and nothing else`()
        throws
    {
        let root = FileManager.default.temporaryDirectory.appending(path: "webdata-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let caches = [
            root.appending(path: "WebsiteData/Default/abc/def/CacheStorage"),
            root.appending(path: "WebsiteDataStore/bccde0fb/Origins/x/y/CacheStorage"),
            root.appending(path: "WebsiteDataStore/bccde0fb/NetworkCache"),
            root.appending(path: "WebsiteDataStore/bccde0fb/MediaCache")
        ]
        let kept = [
            root.appending(path: "WebsiteData/Default/abc/def/IndexedDB"),
            root.appending(path: "WebsiteData/LocalStorage"),
            root.appending(path: "WebsiteDataStore/bccde0fb/Cookies")
        ]
        for folder in caches + kept {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let marked = WebKitFolders.excludeCaches(under: root)
        #expect(marked == 4, "\(marked)")
        for folder in caches { #expect(try Self.excluded(folder), "\(folder.path)") }
        for folder in kept { #expect(try !Self.excluded(folder), "\(folder.path)") }
        #expect(WebKitFolders.excludeCaches(under: root) == 0, "already excluded: nothing to do again")
    }

    private static func excluded(_ url: URL) throws -> Bool {
        var fresh = url
        fresh.removeAllCachedResourceValues()
        return try fresh.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true
    }
}
