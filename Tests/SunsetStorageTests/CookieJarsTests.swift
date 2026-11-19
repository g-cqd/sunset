import Foundation
import Testing

@testable import SunsetStorage

/// Task t114 (design 0007, threat A4): WebKit's cookie jars are sealed at quit and opened at launch, so a copy or a backup of
/// `~/Library` taken while Sunset is closed holds no session token in the clear. Probed (diary 2026-11-19-12): flushed, then
/// moved aside at quit, a jar is not written again by WebKit; put back before a store opens, its cookies are read.
@Suite("Cookie jars: sealed at quit, opened at launch")
struct CookieJarsTests {
    private let id = "studio.aemi.sunset"
    private let seal = Seal(key: .random(), purpose: .cookies)

    private func library() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appending(path: "jars-\(UUID().uuidString)")
        let store = root.appending(path: "WebKit/\(id)/WebsiteDataStore/6E1F4C2A-0000-4000-8000-00000000A001/Cookies")
        try FileManager.default.createDirectory(at: store, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: root.appending(path: "HTTPStorages"),
            withIntermediateDirectories: true
        )
        try Data("default jar".utf8).write(to: root.appending(path: "HTTPStorages/\(id).binarycookies"))
        try Data("profile jar".utf8).write(to: store.appending(path: "Cookies.binarycookies"))
        return root
    }

    @Test func `sealed at quit: no jar left in the clear, each sealed 0600; opened at launch as it was`() throws {
        let root = try library()
        defer { try? FileManager.default.removeItem(at: root) }
        let jars = CookieJars(library: root, bundleID: id)
        #expect(jars.clear().count == 2)
        #expect(jars.seal(with: seal) == 2)
        #expect(jars.clear().isEmpty)
        for sealed in jars.sealed() {
            let data = try Data(contentsOf: sealed)
            #expect(Seal.isSealed(data))
            #expect(!String(decoding: data, as: UTF8.self).contains("jar"))
            #expect((try FileManager.default.attributesOfItem(atPath: sealed.path)[.posixPermissions] as? Int) == 0o600)
        }
        #expect(jars.open(with: seal) == .init(opened: 2, newer: 0, unreadable: 0))
        #expect(jars.sealed().isEmpty)
        let texts = try jars.clear().map { String(decoding: try Data(contentsOf: $0), as: UTF8.self) }.sorted()
        #expect(texts == ["default jar", "profile jar"])
    }

    @Test func `a jar written after the seal is newer and stays; a jar that does not open is kept, never deleted`()
        throws
    {
        let root = try library()
        defer { try? FileManager.default.removeItem(at: root) }
        let jars = CookieJars(library: root, bundleID: id)
        jars.seal(with: seal)
        // WebKit wrote the default jar again (a cookie changed after the flush): it is newer than the sealed one.
        let defaultJar = root.appending(path: "HTTPStorages/\(id).binarycookies")
        try Data("newer".utf8).write(to: defaultJar)
        // Another key (a reset, another Mac's copy): the profile's sealed jar does not open.
        let other = Seal(key: .random(), purpose: .cookies)
        let outcome = jars.open(with: other)
        #expect(outcome == .init(opened: 0, newer: 1, unreadable: 1))
        #expect(String(decoding: try Data(contentsOf: defaultJar), as: UTF8.self) == "newer")
        #expect(jars.sealed().count == 1, "the unreadable one is kept for the right key")
        #expect(jars.open(with: seal) == .init(opened: 1, newer: 0, unreadable: 0))
    }

    @Test func `a sealed jar moved to another store's place does not open there`() throws {
        let root = try library()
        defer { try? FileManager.default.removeItem(at: root) }
        let jars = CookieJars(library: root, bundleID: id)
        jars.seal(with: seal)
        let sealed = jars.sealed().sorted { $0.path < $1.path }
        let swapped = try Data(contentsOf: sealed[0])
        try Data(contentsOf: sealed[1]).write(to: sealed[0])
        try swapped.write(to: sealed[1])
        #expect(jars.open(with: seal).unreadable == 2)
    }
}
