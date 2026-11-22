import Foundation
import Testing

@testable import SunsetStorage

/// Sunset WebKit reads Sunset's jars to bring its cookies over: each store's, sealed or (Sunset running) in the clear,
/// opened in memory only: nothing of Sunset's is written, moved or unsealed on disk.
@Suite("Sunset's cookie jars, read by Sunset WebKit")
struct CookieJarsReadTests {
    private let id = "studio.aemi.sunset"
    private let profile = UUID(uuid: (0x6E, 0x1F, 0x4C, 0x2A, 0, 0, 0x40, 0, 0x80, 0, 0, 0, 0, 0, 0xA0, 0x01))

    private func library(_ jar: Data) throws -> URL {
        let root = FileManager.default.temporaryDirectory.appending(path: "jars-\(UUID().uuidString)")
        let store = root.appending(path: "WebKit/\(id)/WebsiteDataStore/\(profile.uuidString)/Cookies")
        try FileManager.default.createDirectory(at: store, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: root.appending(path: "HTTPStorages"),
            withIntermediateDirectories: true
        )
        try jar.write(to: root.appending(path: "HTTPStorages/\(id).binarycookies"))
        try jar.write(to: store.appending(path: "Cookies.binarycookies"))
        return root
    }

    @Test func `each store's cookies, sealed or in the clear; Sunset's files as they were`() throws {
        let jar = try #require(CookieJarFixture.jar)
        let root = try library(jar)
        defer { try? FileManager.default.removeItem(at: root) }
        let seal = Seal(key: .random(), purpose: .cookies)
        let jars = CookieJars(library: root, bundleID: id)
        #expect(jars.seal(with: seal) == 2)
        // Sunset running again: its default jar is in the clear; the profile's stays sealed.
        try jar.write(to: root.appending(path: "HTTPStorages/\(id).binarycookies"))
        let before = jars.places().map { FileManager.default.fileExists(atPath: $0.path) }
        let read = jars.read(with: seal)
        #expect(read.unreadable == 0)
        #expect(read.stores[nil]?.count == 3 && read.stores[profile]?.count == 3)
        #expect(
            jars.places().map { FileManager.default.fileExists(atPath: $0.path) } == before,
            "nothing unsealed on disk"
        )
        #expect(jars.sealed().count == 2, "both seals still there")
        // Another key's seal does not open: said, not read.
        let other = jars.read(with: Seal(key: .random(), purpose: .cookies))
        #expect(other.unreadable == 1 && other.stores[profile] == nil && other.stores[nil]?.count == 3)
    }
}
