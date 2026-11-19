// t115: what WebKit's protections cost (2026-11-19, release). (1) A plain-http local server loaded with HTTPS first and a
// fallback, against as asked: the address finally shown, and the time. (2) A script's work with the hardened mode (no JIT)
// against none: a numeric loop and a string-and-object one, 5 runs each after a warm-up, in a fresh view each time.
import AppKit
import WebKit

@MainActor final class Loader: NSObject, WKNavigationDelegate {
    var done: CheckedContinuation<Void, Never>?
    func webView(_ w: WKWebView, didFinish n: WKNavigation!) { finish() }
    func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: any Error) { finish() }
    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: any Error) { finish() }
    func finish() {
        done?.resume()
        done = nil
    }
}

@MainActor func view(_ policy: WKWebpagePreferences.UpgradeToHTTPSPolicy, hardened: Bool) -> (WKWebView, Loader) {
    let configuration = WKWebViewConfiguration()
    let preferences = WKWebpagePreferences()
    preferences.preferredHTTPSNavigationPolicy = policy
    if #available(macOS 26.4, *) { preferences.securityRestrictionMode = hardened ? .maximizeCompatibility : .none }
    configuration.defaultWebpagePreferences = preferences
    configuration.websiteDataStore = .nonPersistent()
    let view = WKWebView(frame: .init(x: 0, y: 0, width: 800, height: 600), configuration: configuration)
    let loader = Loader()
    view.navigationDelegate = loader
    return (view, loader)
}

func ms(_ start: UInt64) -> Double { Double(DispatchTime.now().uptimeNanoseconds - start) / 1e6 }
func median(_ xs: [Double]) -> Double { xs.sorted()[xs.count / 2] }

let work = """
    const t0 = performance.now();
    let x = 0; for (let i = 0; i < 30000000; i++) { x = (x + i * 7) % 1000003; }
    const t1 = performance.now();
    const parts = []; for (let i = 0; i < 300000; i++) { parts.push({ k: "k" + i, v: i % 97 }); }
    const joined = parts.map(p => p.k + ":" + p.v).join(",").length;
    const t2 = performance.now();
    return [t1 - t0, t2 - t1, x + joined];
    """

Task { @MainActor in
    guard
        let local = URL(
            string: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "http://localhost:8770/index.html"
        )
    else { exit(1) }
    for (label, policy) in [
        ("as asked", WKWebpagePreferences.UpgradeToHTTPSPolicy.keepAsRequested),
        ("https first, fallback", .automaticFallbackToHTTP)
    ] {
        var times: [Double] = []
        var shown = ""
        for _ in 0 ..< 5 {
            let (v, loader) = view(policy, hardened: false)
            let t = DispatchTime.now().uptimeNanoseconds
            await withCheckedContinuation {
                loader.done = $0
                v.load(URLRequest(url: local))
            }
            times.append(ms(t))
            shown = v.url?.absoluteString ?? "nil"
        }
        print("\(label): \(local) -> \(shown), load p50 \(Int(median(times))) ms (\(times.map { Int($0) }))")
    }
    for hardened in [false, true] {
        var numeric: [Double] = []
        var objects: [Double] = []
        for run in 0 ..< 6 {
            let (v, loader) = view(.keepAsRequested, hardened: hardened)
            await withCheckedContinuation {
                loader.done = $0
                v.loadHTMLString("<p>x</p>", baseURL: URL(string: "https://bench.example/"))
            }
            let result = (try? await v.callAsyncJavaScript(work, contentWorld: .page)) as? [Double] ?? [-1, -1]
            if run > 0 {
                numeric.append(result[0])
                objects.append(result[1])
            }
        }
        print(
            "\(hardened ? "hardened (no JIT)" : "not hardened"): numeric loop p50 \(Int(median(numeric))) ms, strings and objects p50 \(Int(median(objects))) ms"
        )
    }
    exit(0)
}
NSApplication.shared.run()
