import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Extension pages would not open. Probed: Sunset never set a context's unique identifier, so WebKit made a new one at every
/// launch: the extension's pages had a new address each time, and WebKit keeps an extension's storage only for a context
/// with an identifier of its own (WebExtensionController:: storageDirectory): every extension lost its settings at each
/// launch. The installed entry's identifier is the context's. In `ExtensionHostTests`' suite: they share
/// `ExtensionHosts.shared`, so they run one after another (run beside it, a reset there made this fail, 2026-11-21).
extension ExtensionHostTests {
    @Test func `its identifier and its pages' address are the installed entry's, launch after launch`() async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "extid-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let manifest =
            #"{"manifest_version": 3, "name": "Same", "version": "1.0", "description": "A test.", "options_page": "o.html"}"#
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        try Data("<!doctype html>o".utf8).write(to: folder.appending(path: "o.html"))
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        defer { ExtensionHosts.shared.reset() }
        let profile = UUID()
        let host = try #require(ExtensionHosts.shared.host(for: profile))
        await host.ready()
        let entry = try await host.install(ExtensionHost.read(folder))
        let first = try #require(host.context(of: entry.id))
        #expect(first.uniqueIdentifier == entry.id.uuidString.lowercased())
        #expect(first.baseURL.host() == entry.id.uuidString.lowercased())

        // The next launch: a host made again from the same folder.
        ExtensionHosts.shared.reset()
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        let again = try #require(ExtensionHosts.shared.host(for: profile))
        await again.ready()
        let second = try #require(again.context(of: entry.id))
        #expect(second.uniqueIdentifier == first.uniqueIdentifier)
        #expect(second.baseURL == first.baseURL)
    }
}
