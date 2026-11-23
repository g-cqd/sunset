import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// Protected video (the owner's note n122, 2026-11-23: CNN said the browser does not support its DRM). A page of Sunset
/// sees Apple's FairPlay as Safari offers it: through EME (`com.apple.fps`, its keys made) and through WebKit's older API;
/// private or not. Widevine is not there, as in Safari.
@MainActor
@Suite("Encrypted media: what a page sees") struct EncryptedMediaTests {
    @Test(arguments: [false, true])
    func `FairPlay is offered, private or not`(isPrivate: Bool) async throws {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        if isPrivate { settings.privacy = PagePrivacy() }
        let page = WebContent(url: nil, settings: settings)
        page.setState(focused: true, visible: true)
        defer { page.stop() }
        let view = try #require(page.webView)
        view.loadHTMLString("<body></body>", baseURL: URL(string: "https://video.example/"))
        let script = """
            (async () => {
              const config = [{ initDataTypes: ["skd"], videoCapabilities: [{ contentType: 'video/mp4; codecs="avc1.42E01E"' }] }];
              const out = [isSecureContext, typeof WebKitMediaKeys === "function"
                && WebKitMediaKeys.isTypeSupported("com.apple.fps.1_0", "video/mp4")];
              try { await (await navigator.requestMediaKeySystemAccess("com.apple.fps", config)).createMediaKeys(); out.push("keys"); }
              catch (e) { out.push(String(e.name || e)); }
              try { await navigator.requestMediaKeySystemAccess("com.widevine.alpha", config); out.push("widevine"); }
              catch (e) { out.push("no widevine"); }
              document.body.dataset.drm = out.join(",");
            })();
            0
            """
        for _ in 0 ..< 50 where view.isLoading || view.url == nil { await RealWait.pass(.milliseconds(100)) }
        _ = try? await view.evaluateJavaScript(script)
        var seen: String?
        for _ in 0 ..< 50 where seen == nil {
            await RealWait.pass(.milliseconds(100))
            seen = try? await view.evaluateJavaScript("document.body.dataset.drm ?? null") as? String
        }
        #expect(seen == "true,true,keys,no widevine")
    }
}
