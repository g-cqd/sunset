// Run: swiftc -O -o /tmp/site-probe Scripts/probes/webkit-site-as-chrome.swift && /tmp/site-probe https://app.site.example/
// (roadmap 0045 F, 2026-11-18). Loads a site in a WKWebView in a window, once per way Sunset can show it, and prints where it
// ended, its title, the start of its text, its errors and its console, and writes a picture of each to /tmp/site-probe-<name>.png.
import AppKit
import WebKit

@MainActor final class Probe: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    var lines: [String] = []
    func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {
        lines.append("\(message.body)")
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: any Error) {
        lines.append("navigation failed: \(error.localizedDescription)")
    }
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: any Error
    ) {
        lines.append("provisional navigation failed: \(error.localizedDescription)")
    }
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        if navigationAction.targetFrame?.isMainFrame ?? false {
            lines.append("goes to \(navigationAction.request.url?.absoluteString ?? "?")")
        }
        return .allow
    }
}

let capture = """
    (() => {
      const post = (kind, text) => { try { webkit.messageHandlers.probe.postMessage(kind + ': ' + String(text).slice(0, 400)); } catch (e) {} };
      addEventListener('error', e => post('error', (e.message || e.target?.src || e.target?.href || e) + ' @' + (e.filename || '') + ':' + (e.lineno || '')), true);
      addEventListener('unhandledrejection', e => post('rejection', e.reason && (e.reason.stack || e.reason.message) || e.reason));
      addEventListener('securitypolicyviolation', e => post('csp', e.violatedDirective + ' ' + e.blockedURI));
      for (const level of ['error', 'warn', 'log']) {
        const original = console[level];
        console[level] = (...args) => { post('console.' + level, args.map(a => { try { return typeof a === 'string' ? a : JSON.stringify(a); } catch (e) { return String(a); } }).join(' ')); original.apply(console, args); };
      }
    })();
    """

/// AgentScript.source as of 2026-11-18, or the file given by SUNSET_AGENT_SCRIPT.
let agentScript: String = {
    if let path = ProcessInfo.processInfo.environment["SUNSET_AGENT_SCRIPT"],
        let text = try? String(contentsOfFile: path, encoding: .utf8)
    {
        return text
    }
    return ""
}()

let chrome =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36"

@MainActor func run(_ name: String, url: URL, agent: String?, scripts: Bool, seconds: Double) async {
    let probe = Probe()
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()
    configuration.applicationNameForUserAgent = "Version/26.0 Safari/605.1.15"
    configuration.userContentController.add(probe, name: "probe")
    configuration.userContentController.addUserScript(
        WKUserScript(source: capture, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    )
    if scripts, !agentScript.isEmpty {
        configuration.userContentController.addUserScript(
            WKUserScript(source: agentScript, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .page)
        )
    }
    let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 1200, height: 800), configuration: configuration)
    view.customUserAgent = agent
    view.navigationDelegate = probe
    let window = NSWindow(
        contentRect: CGRect(x: 0, y: 0, width: 1200, height: 800),
        styleMask: [.titled],
        backing: .buffered,
        defer: false
    )
    window.isReleasedWhenClosed = false
    window.contentView = view
    window.orderBack(nil)
    view.load(URLRequest(url: url))
    try? await Task.sleep(for: .seconds(seconds))
    let state =
        (try? await view.evaluateJavaScript(
            "JSON.stringify({href: location.href, title: document.title, ua: navigator.userAgent, vendor: navigator.vendor, text: (document.body ? document.body.innerText : '').slice(0, 300)})"
        ) as? String) ?? "?"
    print("== \(name)\n\(state)")
    print(
        "  item initialURL:",
        view.backForwardList.currentItem?.initialURL.absoluteString ?? "-",
        "back:",
        view.backForwardList.backList.map(\.url.absoluteString)
    )
    for line in probe.lines { print("  " + line) }
    if let image = try? await view.takeSnapshot(configuration: nil), let tiff = image.tiffRepresentation,
        let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
    {
        try? png.write(to: URL(fileURLWithPath: "/tmp/site-probe-\(name).png"))
    }
    window.close()
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let target = URL(string: CommandLine.arguments.dropFirst().first ?? "") ?? URL(fileURLWithPath: "/")
let seconds = Double(ProcessInfo.processInfo.environment["SECONDS_TO_WAIT"] ?? "") ?? 12
Task { @MainActor in
    await run("safari", url: target, agent: nil, scripts: false, seconds: seconds)
    await run("chrome-ua", url: target, agent: chrome, scripts: false, seconds: seconds)
    await run("chrome-scripts", url: target, agent: chrome, scripts: true, seconds: seconds)
    exit(0)
}
app.run()
