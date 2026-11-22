import Foundation
import Testing

@testable import SunsetWebModel

/// Each extension installed is a copy in its profile's folder, listed in that folder's index: on or off, in private
/// windows or not (off by default), what it was granted at install.
@Suite("The extensions installed, per profile")
struct ExtensionStoreTests {
    private func folder() throws -> URL {
        let url = URL(filePath: NSTemporaryDirectory()).appending(path: "extstore-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func `installed, a copy is kept and listed; turned off and allowed in private, kept so; removed, gone`()
        throws
    {
        let root = try folder()
        defer { try? FileManager.default.removeItem(at: root) }
        let package = root.appending(path: "a.crx")
        try ExtensionPackageTests.crx3(header: Data(count: 8), zip: ExtensionPackageTests.zipStart).write(to: package)
        let profile = UUID()
        var store = ExtensionStore(root: root.appending(path: "Extensions"), profile: profile)
        let installed = try store.install(from: package, name: "A", granted: ["storage", "https://a.example/*"])
        #expect(store.installed.map(\.name) == ["A"])
        #expect(installed.enabled && !installed.inPrivate)
        #expect(
            try Data(contentsOf: store.file(of: installed)) == ExtensionPackageTests.zipStart,
            "the zip WebKit loads"
        )
        store.set(installed.id, enabled: false)
        store.set(installed.id, inPrivate: true)
        let reread = ExtensionStore(root: root.appending(path: "Extensions"), profile: profile)
        #expect(reread.installed.first?.enabled == false && reread.installed.first?.inPrivate == true)
        #expect(reread.installed.first?.granted == ["storage", "https://a.example/*"])
        #expect(
            ExtensionStore(root: root.appending(path: "Extensions"), profile: UUID()).installed.isEmpty,
            "another profile's"
        )
        store.remove(installed.id)
        #expect(store.installed.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: store.file(of: installed).path))
    }

    @Test func `an unpacked folder is copied as it is; a package refused installs nothing`() throws {
        let root = try folder()
        defer { try? FileManager.default.removeItem(at: root) }
        let unpacked = root.appending(path: "unpacked")
        try FileManager.default.createDirectory(at: unpacked, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: unpacked.appending(path: "manifest.json"))
        var store = ExtensionStore(root: root.appending(path: "Extensions"), profile: nil)
        let installed = try store.install(from: unpacked, name: "U", granted: [])
        #expect(FileManager.default.fileExists(atPath: store.file(of: installed).appending(path: "manifest.json").path))
        let bad = root.appending(path: "bad.crx")
        try Data("<html>".utf8).write(to: bad)
        #expect(throws: ExtensionPackage.Refused.self) { try store.install(from: bad, name: "B", granted: []) }
        #expect(store.installed.map(\.name) == ["U"])
    }
}
