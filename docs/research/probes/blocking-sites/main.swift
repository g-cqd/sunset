// t109 F: what Sunset's blocking does to real pages over the network (release, 2026-11-20). Each site loaded RUNS times
// per condition, the conditions alternated, each load in a fresh store (no cache, no cookies): the time to the load event,
// the requests made, the bytes moved (`performance` entries), with no list and with EasyList and EasyPrivacy compiled as
// Sunset compiles them.
import AppKit
import WebKit

@MainActor final class Loader: NSObject, WKNavigationDelegate {
    var done: CheckedContinuation<Bool, Never>?
    func webView(_ w: WKWebView, didFinish n: WKNavigation!) { finish(true) }
    func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: any Error) { finish(false) }
    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: any Error) {
        finish(false)
    }
    func finish(_ ok: Bool) {
        done?.resume(returning: ok)
        done = nil
    }
}

func median(_ xs: [Double]) -> Double { xs.isEmpty ? .nan : xs.sorted()[xs.count / 2] }

let folder = URL(fileURLWithPath: CommandLine.arguments[1])
let runs = Int(ProcessInfo.processInfo.environment["RUNS"] ?? "5") ?? 5
let sites = [
    "https://www.theguardian.com/international", "https://www.lemonde.fr/", "https://edition.cnn.com/",
    "https://www.bbc.com/news", "https://www.reddit.com/", "https://stackoverflow.com/questions",
    "https://en.wikipedia.org/wiki/Sunset", "https://www.allrecipes.com/"
]

MainActor.assumeIsolated {
    Task { @MainActor in
        guard let store = WKContentRuleListStore(url: folder.appending(path: "store")) else { exit(1) }
        var lists: [WKContentRuleList] = []
        for name in ["easylist", "easyprivacy"] {
            guard
                let file = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                    .first(where: { $0.lastPathComponent.contains("_\(name)_txt") }),
                let text = try? String(contentsOf: file, encoding: .utf8)
            else { continue }
            for (index, part) in BlockingRules.convert(text).parts().enumerated() {
                let json = String(decoding: (try? BlockingRules.json(part)) ?? Data(), as: UTF8.self)
                if let list = try? await store.compileContentRuleList(
                    forIdentifier: "sites-\(name)-\(index)",
                    encodedContentRuleList: json
                ) {
                    lists.append(list)
                }
            }
        }
        print("lists compiled: \(lists.count)")
        fflush(stdout)
        let window = NSWindow(
            contentRect: .init(x: 0, y: 0, width: 1280, height: 900),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        for site in sites {
            guard let url = URL(string: site) else { continue }
            var times: [Bool: [Double]] = [:]
            var requests: [Bool: [Double]] = [:]
            var bytes: [Bool: [Double]] = [:]
            for run in 0 ..< runs * 2 {
                let blocking = run % 2 == 1
                let configuration = WKWebViewConfiguration()
                configuration.websiteDataStore = .nonPersistent()
                if blocking { for list in lists { configuration.userContentController.add(list) } }
                let view = WKWebView(frame: window.contentView?.bounds ?? .zero, configuration: configuration)
                view.customUserAgent =
                    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"
                window.contentView?.addSubview(view)
                let loader = Loader()
                view.navigationDelegate = loader
                let start = DispatchTime.now().uptimeNanoseconds
                // At most 30 s: a page whose load event never comes (a request kept open) is counted as not finished.
                let finished = await withCheckedContinuation { (done: CheckedContinuation<Bool, Never>) in
                    loader.done = done
                    view.load(URLRequest(url: url, timeoutInterval: 30))
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(30))
                        view.stopLoading()
                        loader.finish(false)
                    }
                }
                let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start) / 1e6
                try? await Task.sleep(for: .seconds(2))
                let measured =
                    try? await view.callAsyncJavaScript(
                        "const r = performance.getEntriesByType('resource'); return [r.length, r.reduce((s, e) => s + (e.transferSize || 0), 0)];",
                        contentWorld: .page
                    ) as? [Double]
                if finished, let measured, measured.count == 2 {
                    times[blocking, default: []].append(elapsed)
                    requests[blocking, default: []].append(measured[0])
                    bytes[blocking, default: []].append(measured[1] / 1024)
                }
                view.removeFromSuperview()
            }
            func line(_ blocking: Bool) -> String {
                String(
                    format: "load p50 %5.0f ms, %4.0f requests, %6.0f KB",
                    median(times[blocking] ?? []),
                    median(requests[blocking] ?? []),
                    median(bytes[blocking] ?? [])
                )
            }
            print(
                site.padding(toLength: 46, withPad: " ", startingAt: 0),
                "| none:",
                line(false),
                "| lists:",
                line(true),
                "| n=\(times[false]?.count ?? 0)/\(times[true]?.count ?? 0)"
            )
            fflush(stdout)
        }
        exit(0)
    }
    NSApplication.shared.run()
}
