import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// In `ExtensionHostTests`' suite: they share `ExtensionHosts.shared`, so they run one after another (run beside it, a reset
/// here made "an extension opens a tab" fail, 2026-11-21).
extension ExtensionHostTests {
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

    /// The owner's note n99 (2026-11-23): an extension's popup does nothing in a private window. Its button clicked for a
    /// private page's tab, in a private window: the popup is asked for when the extension is allowed in private windows.
    @Test(arguments: [true, false])
    func `in a private window, clicked: its popup asked for when allowed there`(allowed: Bool) async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "extaction-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        defer { ExtensionHosts.shared.reset() }
        let host = try await install(
            #"""
            {"manifest_version": 3, "name": "Act", "version": "1.0", "description": "A test.",
             "action": {"default_title": "Say hi", "default_popup": "p.html"}, "permissions": ["activeTab"]}
            """#,
            files: [
                "p.html": #"<body><script src="p.js"></script></body>"#,
                "p.js": """
                chrome.tabs.query({ active: true, currentWindow: true })
                  .then(t => { document.body.dataset.seen = t.length + (t[0] ? " " + (t[0].url ?? "") : ""); })
                  .catch(e => { document.body.dataset.seen = "error " + e; });
                """
            ],
            root: root
        )
        let entry = try #require(host.installed.first)
        host.set(entry.id, inPrivate: allowed)
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.profile = host.profile
        settings.privacy = PagePrivacy()
        let server = try EchoServer()
        let page = WebContent(url: URL(string: "http://127.0.0.1:\(server.port)/private"), settings: settings)
        let window = ExtensionWindow(profile: host.profile, isPrivate: true, pages: { [page] }, shown: { page })
        ExtensionHosts.shared.windows = { [window] }
        ExtensionHosts.shared.focused = { window }
        page.setState(focused: true, visible: true)
        ExtensionHosts.shared.sync()
        defer { page.stop() }
        let tab = try #require(page.extensionTab, "the private page is a tab of the controller")
        let action = try #require(host.actions(for: tab).first)
        #expect(action.inPrivate == allowed, "the bar is told, to dim it and offer to allow it")
        var popup: WKWebView?
        host.presentPopup = { _, shown in popup = shown.popupWebView }
        host.perform(action.id, for: tab)
        try await waitUntil(timeout: .seconds(10), label: "the popup asked for") { popup != nil }
        let view = try #require(popup)
        var seen = "none"
        for _ in 0 ..< 60 where seen == "none" {
            await RealWait.pass(.milliseconds(100))
            seen = (try? await view.evaluateJavaScript("document.body.dataset.seen ?? 'none'")) as? String ?? "none"
        }
        // Allowed: the popup sees the private page as the active tab. Not allowed: it sees none, so it cannot work there.
        #expect(seen == (allowed ? "1 http://127.0.0.1:\(server.port)/private" : "0"), "\(seen)")
        if !allowed {
            host.allowInPrivate(action.id)
            #expect(host.actions(for: tab).first?.inPrivate == true && host.installed.first?.inPrivate == true)
        }
    }
}
