import Foundation
import SunsetWeb
import SunsetWebModel
import Testing

extension ExtensionHostTests {
    /// Seen 2026-11-21 (the owner: uBlock Origin's dashboard shows every box unchecked; probed, diary 2026-11-21-03): a
    /// Firefox extension that asks for `privacy` finds none in WebKit, and uBlock Origin's background then throws on each
    /// request for its settings. Sunset gives such an extension Firefox's `privacy` settings, read-only: each reads as
    /// WebKit's own and "not_controllable", a change is refused (`false`, as Firefox answers a setting it does not change).
    /// An extension that does not ask for `privacy` meets none.
    @Test(arguments: [true, false])
    func `an extension that asks for privacy reads the settings and changes none`(asks: Bool) async throws {
        let root = URL(filePath: NSTemporaryDirectory()).appending(path: "exthost-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appending(path: "src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let permissions = (asks ? [#""privacy""#] : []) + [#""http://127.0.0.1/*""#]
        let manifest = """
            {"manifest_version": 2, "name": "Private", "version": "1.0", "description": "A test.",
             "permissions": [\(permissions.joined(separator: ", "))], "background": {"scripts": ["b.js"]},
             "content_scripts": [{"matches": ["http://127.0.0.1/*"], "js": ["c.js"], "run_at": "document_end"}]}
            """
        try Data(manifest.utf8).write(to: folder.appending(path: "manifest.json"))
        try Data(
            """
            const seen = (async () => {
              if (typeof browser.privacy === "undefined") return { privacy: "none" };
              const p = browser.privacy;
              const got = await p.network.networkPredictionEnabled.get({});
              const audit = await p.websites.hyperlinkAuditingEnabled.get({});
              return {
                privacy: typeof p, prediction: got.value, control: got.levelOfControl, audit: audit.value,
                webrtc: (await p.network.webRTCIPHandlingPolicy.get({})).value,
                set: await p.network.networkPredictionEnabled.set({ value: false, scope: "regular" }),
                cleared: await p.websites.hyperlinkAuditingEnabled.clear({ scope: "regular" }),
                after: (await p.network.networkPredictionEnabled.get({})).value,
                change: typeof p.network.networkPredictionEnabled.onChange.addListener
              };
            })();
            browser.runtime.onMessage.addListener(() => seen);
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
        let found = try await dataset(of: "/private", private: false, profile: profile, port: server.port)
        let answer = try #require(found["worker"] as? String)
        let expected =
            asks
            ? [
                #""privacy":"object""#, #""prediction":true"#, #""control":"not_controllable""#, #""audit":true"#,
                #""webrtc":"default""#, #""set":false"#, #""cleared":false"#, #""after":true"#, #""change":"function""#
            ] : [#""privacy":"none""#]
        for part in expected { #expect(answer.contains(part), "\(part) in \(answer)") }
    }
}
