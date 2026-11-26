import Foundation
import Testing

@testable import SunsetStorage

/// Threat model A4: what sites keep is sealed at quit and opened at launch; caches are left as they are (out of backups
/// instead).
@Suite("Sites' storage: sealed at quit, opened at launch")
struct SiteStorageTests {
    private let id = "studio.aemi.sunset"
    private let seal = Seal(key: .random(), purpose: .siteData)
    private let kept = [
        "WebsiteData/Default/aa/bb/IndexedDB/12/IndexedDB.sqlite3",
        "WebsiteData/Default/aa/bb/LocalStorage/localstorage.sqlite3",
        "WebsiteData/Default/aa/bb/LocalStorage/localstorage.sqlite3-wal",
        "WebsiteDataStore/P1/ServiceWorkers/SWRegistrations.db",
        "WebsiteDataStore/P1/ResourceLoadStatistics/observations.db",
        "WebsiteDataStore/P1/HSTS/HSTS.plist",
        "WebsiteDataStore/P1/Origins/origin-hash/origin",
        "WebsiteDataStore/P1/IsolatedSites/IsolatedSites.db",
        "WebsiteDataStore/P1/AlternativeServices/AlternativeService.sqlite",
        "WebsiteDataStore/P1/EnhancedSecurity/EnhancedSecuritySites.db",
        "WebExtensions/Default/ext-uuid/LocalStorage.db",
        "WebExtensions/Default/ext-uuid/State.plist",
        "WebExtensions/P1/ext-uuid/DeclarativeNetRequestRules.db"
    ]
    private let caches = [
        "WebsiteData/Default/aa/bb/CacheStorage/salt",
        "WebsiteDataStore/P1/NetworkCache/Version 17/Records/x",
        "WebsiteDataStore/P1/Origins/.DS_Store"
    ]

    private func library() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appending(path: "sites-\(UUID().uuidString)")
        for path in kept + caches {
            let file = root.appending(path: "WebKit/\(id)/\(path)")
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data("secret of \(path)".utf8).write(to: file)
        }
        return root
    }

    @Test func `sealed at quit: no site's data left in the clear, caches untouched; opened at launch as it was`() throws
    {
        let root = try library()
        defer { try? FileManager.default.removeItem(at: root) }
        let storage = SiteStorage(library: root, bundleID: id)
        #expect(storage.files().clear.count == kept.count)
        #expect(storage.seal(with: seal) == kept.count)
        #expect(storage.files().clear.isEmpty)
        for sealed in storage.files().sealed {
            let data = try Data(contentsOf: sealed)
            #expect(Seal.isSealed(data) && !String(decoding: data, as: UTF8.self).contains("secret"))
            #expect((try FileManager.default.attributesOfItem(atPath: sealed.path)[.posixPermissions] as? Int) == 0o600)
        }
        for path in caches {
            let file = root.appending(path: "WebKit/\(id)/\(path)")
            #expect(try String(contentsOf: file, encoding: .utf8) == "secret of \(path)", "a cache is left alone")
        }
        #expect(storage.open(with: seal) == .init(opened: kept.count))
        for path in kept {
            #expect(
                try String(contentsOf: root.appending(path: "WebKit/\(id)/\(path)"), encoding: .utf8)
                    == "secret of \(path)"
            )
        }
        #expect(storage.files().sealed.isEmpty)
    }

    @Test func `a file written after the seal stays; a seal of another key is kept, not opened`() throws {
        let root = try library()
        defer { try? FileManager.default.removeItem(at: root) }
        let storage = SiteStorage(library: root, bundleID: id)
        storage.seal(with: seal)
        let rewritten = root.appending(path: "WebKit/\(id)/\(kept[0])")
        try Data("newer".utf8).write(to: rewritten)
        let other = Seal(key: .random(), purpose: .siteData)
        #expect(storage.open(with: other) == .init(opened: 0, newer: 1, unreadable: kept.count - 1))
        #expect(try String(contentsOf: rewritten, encoding: .utf8) == "newer")
        #expect(storage.files().sealed.count == kept.count - 1)
        #expect(storage.open(with: seal) == .init(opened: kept.count - 1))
    }
}
