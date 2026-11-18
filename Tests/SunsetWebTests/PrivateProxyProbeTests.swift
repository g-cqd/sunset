import AppKit
import Foundation
import Testing
import WebKit

@testable import SunsetWeb

/// A probe (roadmap 0046 B, 2026-11-18): WebKit's private `-[WKWebsiteDataStore _setProxyConfiguration:]` takes a CFNetwork
/// proxy dictionary. Does it take a proxy auto-configuration script, so that a page's requests go where a script decides
/// per address (what an extension's `chrome.proxy` sets with `pac_script`)? Never in the suite: `SUNSET_PRIVATE_PROBE`.
@MainActor @Suite("WebKit's private proxy dictionary (probe)", .serialized, .timeLimit(.minutes(1)))
struct PrivateProxyProbeTests {
    private func load(_ address: String, store: WKWebsiteDataStore) async throws -> String {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = store
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 300, height: 200), configuration: configuration)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        defer { window.close() }
        let loaded = WebProxyTests.Loaded()
        view.navigationDelegate = loaded
        view.load(URLRequest(url: try #require(URL(string: address))))
        _ = await withCheckedContinuation { loaded.done = $0 }
        return (try? await view.evaluateJavaScript("document.title") as? String) ?? ""
    }

    /// A store given the dictionary: set on a store made the public way, or in the private configuration it is made from.
    private func make(_ way: String, dictionary: NSDictionary) throws -> WKWebsiteDataStore {
        if way == "store" {
            let store = WKWebsiteDataStore.nonPersistent()
            _ = store.perform(NSSelectorFromString("_setProxyConfiguration:"), with: dictionary)
            return store
        }
        let type = try #require(NSClassFromString("_WKWebsiteDataStoreConfiguration") as? NSObject.Type)
        let made = type.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue() as? NSObject
        let configuration = try #require(
            made?.perform(NSSelectorFromString("initNonPersistentConfiguration"))?.takeUnretainedValue() as? NSObject
        )
        configuration.setValue(dictionary, forKey: "proxyConfiguration")
        let storeMade = WKWebsiteDataStore.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue() as? NSObject
        return try #require(
            storeMade?.perform(NSSelectorFromString("_initWithConfiguration:"), with: configuration)?
                .takeUnretainedValue()
                as? WKWebsiteDataStore
        )
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SUNSET_PRIVATE_PROBE"] != nil))
    func `a proxy auto-configuration script, through the private dictionary`() async throws {
        let proxy = try await AnsweringProxy.start()
        defer { proxy.stop() }
        let script = """
            function FindProxyForURL(url, host) {
              if (dnsDomainIs(host, "by-script.invalid")) return "PROXY 127.0.0.1:\(proxy.port)";
              return "DIRECT";
            }
            """
        for (name, dictionary) in [
            ("script", [kCFNetworkProxiesProxyAutoConfigEnable as String: 1, "ProxyAutoConfigJavaScript": script]),
            (
                "fixed",
                [
                    kCFNetworkProxiesHTTPEnable as String: 1, kCFNetworkProxiesHTTPProxy as String: "127.0.0.1",
                    kCFNetworkProxiesHTTPPort as String: proxy.port
                ]
            )
        ] as [(String, [String: Any])] {
            for way in ["store", "configuration"] {
                let store = try make(way, dictionary: dictionary as NSDictionary)
                let before = proxy.requests.count
                let title = try await load("http://page.by-script.invalid/", store: store)
                let reached = proxy.requests.count - before
                // A name the script sends direct: it must not reach the proxy.
                _ = try await load("http://elsewhere.invalid/", store: store)
                let direct = proxy.requests.count - before - reached
                print(
                    "probe-private:",
                    name,
                    way,
                    "title:",
                    title,
                    "to the proxy:",
                    reached,
                    "direct name to the proxy:",
                    direct
                )
            }
        }
    }
}
