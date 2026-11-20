import AemiTestKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Roadmap 0109 D: an extension's action, as its button shows it (its title, its badge) and as it runs: clicked, an action with a
/// popup asks Sunset to show it (WebKit's controller delegate), anchored to the button.
@MainActor @Suite("An extension's action", .serialized, .timeLimit(.minutes(1)))
struct ExtensionActionTests {
    private func install(_ manifest: String, files: [String: String], root: URL) async throws -> ExtensionHost {
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        for (name, text) in files { try Data(text.utf8).write(to: folder.appending(path: name)) }
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        let host = try #require(ExtensionHosts.shared.host(for: UUID()))
        await host.ready()
        try await host.install(ExtensionHost.read(folder))
        return host
    }

    @Test func `its title and badge; clicked, its popup asked for`() async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "extaction-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        defer { ExtensionHosts.shared.reset() }
        let host = try await install(
            #"""
            {"manifest_version": 3, "name": "Act", "version": "1.0", "description": "A test.",
             "action": {"default_title": "Say hi", "default_popup": "p.html"},
             "background": {"service_worker": "w.js"}}
            """#,
            files: ["p.html": "<p>hi</p>", "w.js": #"chrome.action.setBadgeText({ text: "7" });"#],
            root: root
        )
        let action = try #require(host.actions(for: nil).first)
        #expect(action.label == "Say hi")
        try await waitUntil(timeout: .seconds(10), label: "the worker set the badge") {
            host.actions(for: nil).first?.badge == "7"
        }
        var asked: [String] = []
        host.presentPopup = { item, _ in asked.append(item.label) }
        host.perform(action.id, for: nil)
        try await waitUntil(timeout: .seconds(10), label: "the popup asked for") { asked == ["Say hi"] }
    }
}
