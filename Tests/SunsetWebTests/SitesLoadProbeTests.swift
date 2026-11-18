import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb

/// Many sites in a row (`SUNSET_SITES_PROBE`, comma-separated), each in its own page of Sunset's, blocking on with the lists
/// of `SUNSET_BLOCKING_LISTS`: how long until the page says it has loaded, what its indicator says then, whether it failed,
/// how much text it shows (roadmap 0045 C).
@MainActor @Suite("Real sites loaded one after another (probe)", .timeLimit(.minutes(10)))
struct SitesLoadProbeTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SUNSET_SITES_PROBE"] != nil))
    func `real sites, as Sunset loads them`() async throws {
        let environment = ProcessInfo.processInfo.environment
        let addresses = (environment["SUNSET_SITES_PROBE"] ?? "").split(separator: ",")
            .compactMap { URL(string: String($0)) }
        let lists = environment["SUNSET_BLOCKING_LISTS"]?.split(separator: ":") ?? []
        if !lists.isEmpty {
            await ContentBlocker.shared.load(
                try lists.map {
                    ContentBlocker.Source(
                        address: "https://lists.example/\($0)",
                        text: try String(contentsOfFile: String($0), encoding: .utf8),
                        updated: .now
                    )
                }
            )
        }
        let clock = ContinuousClock()
        for address in addresses {
            var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
            settings.privacy = PagePrivacy()
            let page = WebContent(url: nil, settings: settings)
            let window = NSWindow(
                contentRect: CGRect(x: 0, y: 0, width: 1200, height: 800),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            page.setState(focused: true, visible: true)
            // A plain WKWebView in the same harness, to tell the harness from Sunset's page.
            let plain = environment["SUNSET_PROBE_PLAIN"] != nil
            let view = plain ? WKWebView(frame: .zero) : try #require(page.webView)
            window.contentView = view
            window.orderBack(nil)
            if plain { view.load(URLRequest(url: address)) }
            let start = clock.now
            if !plain { page.load(address) }
            var loadedAt: Duration?
            for _ in 0 ..< 300 {
                try await Task.sleep(for: .milliseconds(100))
                if !view.isLoading, view.url != nil {
                    loadedAt = clock.now - start
                    break
                }
            }
            await report(address, page: page, view: view, loadedAt: loadedAt)
            page.stop()
            window.close()
        }
    }

    /// What the page says of itself once it ended loading, or did not.
    private func report(_ address: URL, page: WebContent, view: WKWebView, loadedAt: Duration?) async {
        let text =
            (try? await view.evaluateJavaScript("document.body ? document.body.innerText.length : -1")) as? Int
            ?? -2
        let ready =
            (try? await view.evaluateJavaScript(
                "document.readyState + ' | ' + [...document.querySelectorAll('iframe')].map(f => f.src.slice(0, 80)).join(' ; ') + ' | pending images ' + [...document.images].filter(i => !i.complete).length + ' of ' + document.images.length + ' lazy ' + [...document.images].filter(i => i.loading === 'lazy').length + ' height ' + document.documentElement.scrollHeight + ' inner ' + innerHeight + ' | sheets ' + [...document.querySelectorAll('link[rel=stylesheet]')].filter(l => !l.sheet).map(l => l.href).join(' ; ') + ' | video ' + [...document.querySelectorAll('video')].map(v => 'ready ' + v.readyState + ' network ' + v.networkState + ' error ' + (v.error && v.error.code) + ' paused ' + v.paused + ' muted ' + v.muted + ' preload=' + v.preload + ' autoplay=' + v.autoplay + ' src ' + (v.currentSrc || v.src || '').slice(-30)).join(' ; ')"
            )) as? String ?? "?"
        print("probe-site-ready:", ready)
        if let names = try? await view.evaluateJavaScript(
            "performance.getEntriesByType('resource').map(e => e.initiatorType + ' ' + e.name.split('?')[0]).join('\\n')"
        ) as? String {
            try? names.write(toFile: "/tmp/resources-sunset.txt", atomically: true, encoding: .utf8)
        }
        print(
            "probe-site:",
            address.host() ?? "-",
            "loaded:",
            loadedAt.map { "\($0)" } ?? "NOT after 30 s",
            "isLoading:",
            page.isLoading,
            "webView.isLoading:",
            view.isLoading,
            "progress:",
            page.progress ?? -1,
            "estimated:",
            view.estimatedProgress,
            "failure:",
            page.failure.map { "\($0)" } ?? "none",
            "text:",
            text
        )
    }
}
