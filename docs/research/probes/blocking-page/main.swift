// t109 (n58): what the compiled lists cost a page, release: a local page of 4,000 elements (ELEMENTS to change) (no network, so only the
// lists' matching and hiding count), loaded 10 times per condition; then a full style recalculation forced 10 times
// (a class on <html> toggled, layout read). Conditions: no list, EasyPrivacy, EasyList, both (2026-11-19).
import AppKit
import WebKit

func p50(_ xs: [Double]) -> String {
    let s = xs.sorted()
    return String(format: "p50 %.1f ms (p10 %.1f, p90 %.1f)", s[s.count / 2], s[s.count / 10], s[s.count * 9 / 10])
}

@MainActor final class Loader: NSObject, WKNavigationDelegate {
    var done: CheckedContinuation<Void, Never>?
    func webView(_ w: WKWebView, didFinish n: WKNavigation!) {
        done?.resume()
        done = nil
    }
}

let folder = URL(fileURLWithPath: CommandLine.arguments[1])
let page = folder.appending(path: "page.html")
var html = "<!doctype html><html><head><title>p</title></head><body>"
let names = ["content", "article", "sidebar", "nav", "card", "item", "row", "text", "media", "footer"]
let count = Int(ProcessInfo.processInfo.environment["ELEMENTS"] ?? "4000") ?? 4000
for i in 0 ..< count {
    html +=
        "<div class=\"\(names[i % names.count]) c\(i)\" id=\"e\(i)\"><span>Item \(i)</span> <a href=\"/p/\(i)\">link</a></div>"
}
html += "</body></html>"
try? html.write(to: page, atomically: true, encoding: .utf8)

Task { @MainActor in
    guard let store = WKContentRuleListStore(url: folder.appending(path: "store")) else { exit(1) }
    // run.sh compiled probe-0..4 per list in turn: the last list compiled holds identifier probe-4; compile both here by name.
    var compiled: [String: WKContentRuleList] = [:]
    for list in ["easyprivacy", "easylist"] {
        guard
            let file = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                .first(where: { $0.lastPathComponent.contains("_\(list)_txt") })
        else { continue }
        let text = try String(contentsOf: file, encoding: .utf8)
        let json = String(decoding: try BlockingRules.json(BlockingRules.convert(text).rules), as: UTF8.self)
        compiled[list] = try await store.compileContentRuleList(
            forIdentifier: "page-\(list)",
            encodedContentRuleList: json
        )
        if list == "easylist" {
            // The same list without generic hiding: css-display-none rules that name no site (no if-domain).
            let rules = (try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: Any]]) ?? []
            let specific = rules.filter { rule in
                let action = rule["action"] as? [String: Any]
                let trigger = rule["trigger"] as? [String: Any]
                return action?["type"] as? String != "css-display-none" || trigger?["if-domain"] != nil
            }
            let generic = rules.filter {
                ($0["action"] as? [String: Any])?["type"] as? String == "css-display-none"
                    && ($0["trigger"] as? [String: Any])?["if-domain"] == nil
            }
            let selectors = generic.reduce(0) {
                $0
                    + ((($1["action"] as? [String: Any])?["selector"] as? String)?.components(separatedBy: ",").count
                        ?? 0)
            }
            print(
                "EasyList: \(rules.count) rules, generic hiding \(generic.count) rules holding \(selectors) selectors; kept \(specific.count)"
            )
            let data = try JSONSerialization.data(withJSONObject: specific)
            compiled["easylist-specific"] = try await store.compileContentRuleList(
                forIdentifier: "page-specific",
                encodedContentRuleList: String(decoding: data, as: UTF8.self)
            )
        }
    }
    let conditions: [(String, [String])] = [
        ("no list", []), ("EasyPrivacy", ["easyprivacy"]), ("EasyList", ["easylist"]),
        ("both", ["easyprivacy", "easylist"]), ("EasyList without generic hiding", ["easylist-specific"])
    ]
    let window = NSWindow(
        contentRect: .init(x: 0, y: 0, width: 1200, height: 900),
        styleMask: [.titled],
        backing: .buffered,
        defer: false
    )
    for (label, lists) in conditions {
        let configuration = WKWebViewConfiguration()
        for name in lists { if let list = compiled[name] { configuration.userContentController.add(list) } }
        let view = WKWebView(frame: window.contentView?.bounds ?? .zero, configuration: configuration)
        window.contentView?.addSubview(view)
        let loader = Loader()
        view.navigationDelegate = loader
        var loads: [Double] = []
        var styles: [Double] = []
        for run in 0 ..< 11 {
            let start = DispatchTime.now().uptimeNanoseconds
            await withCheckedContinuation {
                loader.done = $0
                view.loadFileURL(page, allowingReadAccessTo: folder)
            }
            let load = Double(DispatchTime.now().uptimeNanoseconds - start) / 1e6
            let style =
                try await view.callAsyncJavaScript(
                    "const t = performance.now(); for (let i = 0; i < 10; i++) { document.documentElement.classList.toggle('x' + i); document.body.offsetHeight; } return (performance.now() - t) / 10;",
                    contentWorld: .page
                ) as? Double ?? -1
            if run > 0 {
                loads.append(load)
                styles.append(style)
            }
        }
        print("\(label): load \(p50(loads)) | full style recalc \(p50(styles))")
        view.removeFromSuperview()
    }
    exit(0)
}
NSApplication.shared.run()
