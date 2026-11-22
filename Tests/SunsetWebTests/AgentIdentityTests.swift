import AemiTestKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Roadmap 0045 F, the second rung made deeper (ADR-0074): what a page's scripts read to tell a browser, read as that
/// browser gives it. The oracle is Chrome Canary 160 headless on this Mac, 2026-11-18 (diary 2026-11-18-03): its values
/// are quoted below as Chrome's; Sunset's are read from a real page shown Chrome, Edge, Firefox or Safari.
@MainActor @Suite("What a page's scripts read of the browser it is shown", .timeLimit(.minutes(1)))
struct AgentIdentityTests {
    @Test func `the brands are Chromium's: its made-up brand and their order follow from the major version`() {
        // Chrome 160's, read from Chrome Canary: Chromium, Google Chrome, then "Not)A;Brand" 99.
        #expect(
            ChromiumBrands.list(major: 160, brand: "Google Chrome").map { "\($0.brand) \($0.version)" }
                == ["Chromium 160", "Google Chrome 160", "Not)A;Brand 99"]
        )
        // Chromium's algorithm (components/embedder_support/user_agent_utils.cc) for another version: not an oracle.
        #expect(
            ChromiumBrands.list(major: 158, brand: "Microsoft Edge").map { "\($0.brand) \($0.version)" }
                == ["Chromium 158", "Not.A/Brand 24", "Microsoft Edge 158"]
        )
    }

    /// Reads `script` in a page shown `agent`.
    private func read(_ script: String, as agent: BrowserAgent) async throws -> [String] {
        let server = try EchoServer()
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.agent = agent
        let page = WebContent(url: nil, settings: settings)
        page.agents = SiteAgents()
        page.setState(focused: true, visible: true)
        page.load(try #require(URL(string: "http://127.0.0.1:\(server.port)/\(agent.rawValue)")))
        try await waitForObservedState { !page.isLoading && page.pageTitle == "echo" }
        let view = try #require(page.webView)
        let value = try await view.callAsyncJavaScript(script, contentWorld: .page)
        page.stop()
        return (value as? [Any] ?? []).map { "\($0)" }
    }

    @Test func `shown Chrome, navigator.userAgentData is a NavigatorUAData as Chrome's`() async throws {
        let read = try await read(
            """
            const data = navigator.userAgentData;
            const high = await data.getHighEntropyValues(['platformVersion', 'architecture', 'nonsense', 'bitness']);
            const refused = await data.getHighEntropyValues('x').then(() => 'resolved', e => e.name);
            return [Object.prototype.toString.call(data), typeof NavigatorUAData, Object.keys(data).join(','),
              Object.getOwnPropertyNames(Object.getPrototypeOf(data)).sort().join(','), Object.keys(high).join(','),
              high.architecture, high.bitness, refused, String(data.getHighEntropyValues),
              Object.isFrozen(data.brands), data.brands === data.brands, JSON.stringify(data) === JSON.stringify(data.toJSON())];
            """,
            as: .chrome
        )
        #expect(
            read == [
                "[object NavigatorUAData]", "function", "",
                "brands,constructor,getHighEntropyValues,mobile,platform,toJSON",
                "architecture,bitness,brands,mobile,platform,platformVersion", AgentScript.architecture, "64",
                "TypeError", "function getHighEntropyValues() { [native code] }", "1", "0", "1"
            ]
        )
    }

    @Test func `shown Chrome, what Sunset set reads as the engine's own, as Chrome writes it`() async throws {
        let read = try await read(
            """
            return [String(Object.getOwnPropertyDescriptor(Navigator.prototype, 'vendor').get),
              Function.prototype.toString.call(Function.prototype.toString), String(Math.max),
              Object.keys(window.chrome).sort().join(','), String(window.chrome.loadTimes), chrome.app.isInstalled,
              typeof chrome.csi().startE, typeof navigator.deviceMemory];
            """,
            as: .chrome
        )
        #expect(
            read == [
                "function get vendor() { [native code] }", "function toString() { [native code] }",
                "function max() { [native code] }", "app,csi,loadTimes", "function () { [native code] }", "0",
                "number", "number"
            ]
        )
    }

    @Test func `shown another browser, what only Safari has is gone; shown Safari, nothing is touched`() async throws {
        let probe = """
            return ['standalone' in navigator, 'GestureEvent' in window, 'WebKitPoint' in window,
              'onwebkitmouseforcechanged' in window, String(Math.max).includes('\\n')];
            """
        let chrome = try await read(probe, as: .chrome)
        let firefox = try await read(probe, as: .firefox)
        let safari = try await read(probe, as: .safari)
        #expect(chrome == ["0", "0", "0", "0", "0"])
        #expect(firefox == ["0", "0", "0", "0", "1"], "Firefox writes it as WebKit")
        #expect(safari == ["1", "1", "1", "1", "1"])
    }

    /// Chrome and Firefox play HLS through Media Source Extensions, not natively: their `canPlayType` says "" for it, where
    /// WebKit says "maybe" (t15, measured 2026-11-21). Other types answer as the engine does.
    @Test func `shown another browser, native HLS is not offered; Safari offers it`() async throws {
        let probe = """
            const v = document.createElement('video');
            return [v.canPlayType('application/vnd.apple.mpegurl'), v.canPlayType('application/x-mpegURL'),
              v.canPlayType('video/mp4; codecs="avc1.42E01E"') !== ''];
            """
        let chrome = try await read(probe, as: .chrome)
        let firefox = try await read(probe, as: .firefox)
        let safari = try await read(probe, as: .safari)
        #expect(chrome == ["", "", "1"])
        #expect(firefox == ["", "", "1"])
        #expect(safari[0] != "" && safari[2] == "1")
    }
}
