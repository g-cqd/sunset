import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// n126 (2026-11-23): picture in picture missing on two news sites' videos. Every frame's address and its videos.
@MainActor @Suite("PiP sites probe", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_PIP_PROBE"] != nil))
final class PiPSitesProbe: NSObject, WKScriptMessageHandler {
    var seen: [String: String] = [:]

    nonisolated func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        MainActor.assumeIsolated {
            let body = message.body as? String ?? ""
            seen[body.prefix(90).description] = body
        }
    }

    @Test(arguments: ["https://www.cnews.fr/les-replays/21h-ferrari", "https://www.foxnews.com/video/5614615980001"])
    func `frames and videos`(address: String) async throws {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.setState(focused: true, visible: true)
        defer { page.stop() }
        let view = try #require(page.webView)
        let world = WKContentWorld.world(name: "probe")
        view.configuration.userContentController.add(self, contentWorld: world, name: "probe")
        let script = """
            setInterval(() => {
              const v = [...document.querySelectorAll('video')].map(v => [v.currentSrc.slice(0, 50), v.paused, v.disablePictureInPicture,
                v.webkitSupportsPresentationMode ? v.webkitSupportsPresentationMode('picture-in-picture') : 'n/a', v.readyState].join('/'));
              const f = document.querySelectorAll('iframe').length;
              webkit.messageHandlers.probe.postMessage(location.href.slice(0, 90) + ' | top=' + (window === top) + ' | iframes=' + f + ' | videos=' + JSON.stringify(v));
            }, 1500);
            """
        view.configuration.userContentController.addUserScript(
            WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false, in: world)
        )
        view.frame = CGRect(x: 0, y: 0, width: 1280, height: 800)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        defer { window.close() }
        view.load(URLRequest(url: try #require(URL(string: address))))
        await RealWait.pass(.seconds(15))
        print("PIP PAGE", address)
        for line in seen.values.sorted() { print("PIP   ", line.prefix(400)) }
    }
}
