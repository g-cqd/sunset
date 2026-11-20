import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Roadmap 0109 B: a page of a profile runs that profile's extensions: the content script on a page it was granted, its worker
/// answering it (WebKit needs the page as a tab: probed, diary 2026-11-20-13). Not in a private page unless allowed there.
@MainActor @Suite("A profile's extensions in its pages", .serialized, .timeLimit(.minutes(1)))
struct ExtensionHostTests {
    static let content = """
        document.documentElement.dataset.ext = "ran";
        chrome.runtime.sendMessage({ hi: true }).then(a => { document.documentElement.dataset.worker = JSON.stringify(a); });
        """
    static let worker = """
        chrome.runtime.onMessage.addListener((m, s, reply) => { reply({ from: "worker" }); return true; });
        """

    private func installHello(in root: URL, profile: UUID) throws {
        let folder = try writeHello(in: root)
        var store = ExtensionStore(root: root.appending(path: "Extensions"), profile: profile)
        try store.install(from: folder, name: "Hello", granted: ["http://127.0.0.1/*"])
    }

    /// The probe's extension, unpacked in `root/src`.
    private func writeHello(in root: URL) throws -> URL {
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let manifest = #"""
            {"manifest_version": 3, "name": "Hello", "version": "1.0", "description": "A test.",
             "host_permissions": ["http://127.0.0.1/*"], "background": {"service_worker": "w.js"},
             "content_scripts": [{"matches": ["http://127.0.0.1/*"], "js": ["c.js"], "run_at": "document_end"}]}
            """#
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        try Data(Self.content.utf8).write(to: folder.appending(path: "c.js"))
        try Data(Self.worker.utf8).write(to: folder.appending(path: "w.js"))
        return folder
    }

    private func dataset(of path: String, private isPrivate: Bool, profile: UUID, port: UInt16) async throws -> [String:
        Any]
    {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.profile = profile
        if isPrivate { settings.privacy = PagePrivacy() }
        let page = WebContent(url: URL(string: "http://127.0.0.1:\(port)\(path)"), settings: settings)
        page.setState(focused: true, visible: true)
        defer { page.stop() }
        let view = try #require(page.webView)
        try await waitUntil(timeout: .seconds(10), label: "loaded") { !view.isLoading && view.url?.path == path }
        // The worker's answer comes after the script; when the script did not run, none comes: three seconds at most.
        let read =
            "({ ext: document.documentElement.dataset.ext ?? 'none', worker: document.documentElement.dataset.worker ?? 'none' })"
        var found = try await view.evaluateJavaScript(read)
        for _ in 0 ..< 30 where (found as? [String: Any])?["worker"] as? String == "none" {
            await RealWait.pass(.milliseconds(100))
            found = try await view.evaluateJavaScript(read)
        }
        return try #require(found as? [String: Any])
    }

    @Test func `a profile's page runs its extension; a private page does not until allowed`() async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "exthost-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let profile = UUID()
        try installHello(in: root, profile: profile)
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        defer { ExtensionHosts.shared.reset() }
        await ExtensionHosts.shared.host(for: profile)?.ready()
        let server = try EchoServer()
        let shown = try await dataset(of: "/a", private: false, profile: profile, port: server.port)
        #expect(shown["ext"] as? String == "ran")
        #expect((shown["worker"] as? String)?.contains("worker") == true, "\(shown)")
        let hidden = try await dataset(of: "/b", private: true, profile: profile, port: server.port)
        #expect(hidden["ext"] as? String == "none", "private, not allowed there")
    }

    /// Roadmap 0109 C: installed, turned off and removed while Sunset runs; read first, for the prompt, then installed.
    @Test func `read for the prompt, installed while running; off, a new page runs it no more; removed, gone`()
        async throws
    {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "exthost-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let profile = UUID()
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        defer { ExtensionHosts.shared.reset() }
        let host = try #require(ExtensionHosts.shared.host(for: profile))
        await host.ready()
        let source = try writeHello(in: root)
        let read = try await ExtensionHost.read(source)
        #expect(read.name == "Hello" && read.version == "1.0")
        #expect(read.lines == ["Read and change pages on 127.0.0.1"])
        let installed = try await host.install(read)
        #expect(host.installed.map(\.name) == ["Hello"])
        let server = try EchoServer()
        #expect(
            try await dataset(of: "/a", private: false, profile: profile, port: server.port)["ext"] as? String == "ran"
        )
        host.set(installed.id, enabled: false)
        #expect(
            try await dataset(of: "/b", private: false, profile: profile, port: server.port)["ext"] as? String == "none"
        )
        host.remove(installed.id)
        #expect(host.installed.isEmpty)
    }

    /// Seen 2026-11-20 (the owner's screenshot: uBO Lite's popup empty): an extension saw no window and no tab; WebKit asks the
    /// controller's delegate for the windows (probed: answered, uBO Lite's popup draws). The page shown is the active tab of a
    /// window the extension sees.
    @Test func `an extension sees the window and the page shown as its active tab`() async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "exthost-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let manifest = #"""
            {"manifest_version": 3, "name": "Tabs", "version": "1.0", "description": "A test.", "permissions": ["tabs"],
             "host_permissions": ["http://127.0.0.1/*"], "background": {"service_worker": "w.js"},
             "content_scripts": [{"matches": ["http://127.0.0.1/*"], "js": ["c.js"], "run_at": "document_end"}]}
            """#
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        try Data(
            """
            chrome.runtime.onMessage.addListener((m, s, reply) => {
              Promise.all([chrome.tabs.query({ active: true, currentWindow: true }), chrome.windows.getCurrent()])
                .then(([tabs, win]) => reply({ urls: tabs.map(t => t.url), window: win.type }))
                .catch(e => reply({ error: String(e) }));
              return true;
            });
            """
            .utf8
        )
        .write(to: folder.appending(path: "w.js"))
        try Data(Self.content.utf8).write(to: folder.appending(path: "c.js"))
        let profile = UUID()
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        defer { ExtensionHosts.shared.reset() }
        let host = try #require(ExtensionHosts.shared.host(for: profile))
        await host.ready()
        try await host.install(ExtensionHost.read(folder))
        let server = try EchoServer()
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.profile = profile
        let page = WebContent(url: URL(string: "http://127.0.0.1:\(server.port)/shown"), settings: settings)
        let window = ExtensionWindow(profile: profile, isPrivate: false, pages: { [page] }, shown: { page })
        ExtensionHosts.shared.windows = { [window] }
        ExtensionHosts.shared.focused = { window }
        page.setState(focused: true, visible: true)
        ExtensionHosts.shared.sync()
        defer { page.stop() }
        let view = try #require(page.webView)
        var answer = "none"
        for _ in 0 ..< 60 where answer == "none" || answer == "pending" {
            await RealWait.pass(.milliseconds(100))
            answer =
                (try? await view.evaluateJavaScript("document.documentElement.dataset.worker ?? 'none'")) as? String
                ?? "none"
        }
        #expect(answer.contains("/shown") && answer.contains("normal"), "\(answer)")
    }

    /// Seen 2026-11-20 (the owner: uBlock Origin from Firefox Add-ons draws nothing; probed, diary 2026-11-20-15): a Firefox
    /// extension's pages meet WebKit's differences from Firefox: a method called apart from its namespace gives undefined, an
    /// empty message name throws, an event WebKit lacks is undefined, `requestIdleCallback` is off. Sunset's script in
    /// extension pages evens them out until our own WebKit fixes them (roadmap 0048 D).
    @Test func `a Firefox extension's background page meets what Firefox gives`() async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "exthost-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let manifest = #"""
            {"manifest_version": 2, "name": "Fox", "version": "1.0", "description": "A test.",
             "permissions": ["webNavigation", "webRequest", "http://127.0.0.1/*"], "background": {"page": "b.html"},
             "content_scripts": [{"matches": ["http://127.0.0.1/*"], "js": ["c.js"], "run_at": "document_end"}]}
            """#
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        try Data(#"<!doctype html><script src="b.js"></script>"#.utf8).write(to: folder.appending(path: "b.html"))
        try Data(
            """
            const getURL = browser.runtime.getURL;
            const seen = {};
            const look = (name, f) => { try { seen[name] = f(); } catch (e) { seen[name] = "throws"; } };
            look("detached", () => typeof getURL(""));
            look("empty", () => browser.i18n.getMessage(""));
            look("event", () => typeof browser.webNavigation.onCreatedNavigationTarget);
            look("changed", () => typeof browser.webRequest.handlerBehaviorChanged);
            look("idle", () => typeof requestIdleCallback);
            browser.runtime.onMessage.addListener(() => Promise.resolve(seen));
            """
            .utf8
        )
        .write(to: folder.appending(path: "b.js"))
        try Data(Self.content.utf8).write(to: folder.appending(path: "c.js"))
        let profile = UUID()
        ExtensionHosts.shared.root = root.appending(path: "Extensions")
        defer { ExtensionHosts.shared.reset() }
        let host = try #require(ExtensionHosts.shared.host(for: profile))
        await host.ready()
        try await host.install(ExtensionHost.read(folder))
        let server = try EchoServer()
        let found = try await dataset(of: "/fox", private: false, profile: profile, port: server.port)
        let answer = try #require(found["worker"] as? String)
        for part in [
            #""detached":"string""#, #""empty":"""#, #""event":"object""#, #""changed":"function""#,
            #""idle":"function""#
        ] {
            #expect(answer.contains(part), "\(part) in \(answer)")
        }
    }
}
