import Foundation
import Testing
import WebKit

@testable import SunsetWebModel

/// The probe's extension, packed as a store packs it, loads in WebKit.
@MainActor @Suite("An extension's package in WebKit")
struct ExtensionPackageLoadTests {
    @Test func `a CRX3 of an extension loads, with its name and what it asks`() async throws {
        let folder = URL(filePath: NSTemporaryDirectory()).appending(path: "ext-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let manifest = #"""
            {"manifest_version": 3, "name": "Packed", "version": "1.0", "description": "A test.",
             "permissions": ["storage"], "host_permissions": ["https://a.example/*"]}
            """#
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        let zip = folder.appending(path: "packed.zip")
        let ditto = Process()
        ditto.executableURL = URL(filePath: "/usr/bin/ditto")
        ditto.arguments = ["-c", "-k", folder.appending(path: "manifest.json").path, zip.path]
        try ditto.run()
        ditto.waitUntilExit()
        let crx = try SignedCRX.signed(Data(contentsOf: zip))
        let unpacked = folder.appending(path: "out.zip")
        try ExtensionPackage.zip(from: crx).write(to: unpacked)
        let loaded = try await WKWebExtension(resourceBaseURL: unpacked)
        #expect(loaded.displayName == "Packed")
        #expect(loaded.requestedPermissions.contains(.storage))
        #expect(loaded.requestedPermissionMatchPatterns.map(\.string) == ["https://a.example/*"])
    }
}
