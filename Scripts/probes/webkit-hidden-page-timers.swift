// Run: swiftc -O -o /tmp/probe Scripts/probes/webkit-hidden-page-timers.swift && /tmp/probe (2026-11-18).
import AppKit
import WebKit

// Does a WKWebView out of a window keep running a page's timers? For each inactiveSchedulingPolicy (and WebKit's default),
// a page counts setInterval ticks (every 50 ms); the view is in a window for 1 s, then out of it for 3 s, then back.
@MainActor final class Probe: NSObject, WKScriptMessageHandler {
    var ticks: [String: Int] = [:]
    var current = ""
    func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {
        ticks[current, default: 0] += 1
    }
}

@MainActor func run(_ name: String, policy: WKPreferences.InactiveSchedulingPolicy?, probe: Probe) async -> (
    Int, Int, Int
) {
    let configuration = WKWebViewConfiguration()
    if let policy { configuration.preferences.inactiveSchedulingPolicy = policy }
    configuration.userContentController.add(probe, name: "tick")
    let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 300, height: 200), configuration: configuration)
    let window = NSWindow(
        contentRect: CGRect(x: 0, y: 0, width: 300, height: 200),
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    window.isReleasedWhenClosed = false
    window.contentView = NSView()
    window.contentView?.addSubview(view)
    window.orderBack(nil)
    view.loadHTMLString(
        "<script>setInterval(() => webkit.messageHandlers.tick.postMessage(1), 50)</script>",
        baseURL: nil
    )
    probe.current = name + ".in"
    try? await Task.sleep(for: .seconds(1.5))
    probe.current = name + ".out"
    view.removeFromSuperview()
    try? await Task.sleep(for: .seconds(20))
    probe.current = name + ".back"
    window.contentView?.addSubview(view)
    try? await Task.sleep(for: .seconds(1))
    window.close()
    return (probe.ticks[name + ".in"] ?? 0, probe.ticks[name + ".out"] ?? 0, probe.ticks[name + ".back"] ?? 0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
Task { @MainActor in
    let probe = Probe()
    let defaultPolicy = WKPreferences().inactiveSchedulingPolicy
    print(
        "default policy raw:",
        defaultPolicy.rawValue,
        "(none 2? throttle 1? suspend 0?)",
        String(describing: defaultPolicy)
    )
    for (name, policy) in [
        ("default", nil), ("suspend", WKPreferences.InactiveSchedulingPolicy.suspend), ("throttle", .throttle),
        ("none", WKPreferences.InactiveSchedulingPolicy.none)
    ] as [(String, WKPreferences.InactiveSchedulingPolicy?)] {
        let (a, b, c) = await run(name, policy: policy, probe: probe)
        print("\(name): in-window 1.5 s \(a) ticks; out of window 20 s \(b) ticks; back 1 s \(c) ticks")
    }
    // Can the policy be changed on a live view? The preferences object of a view's configuration.
    let view = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    let before = view.configuration.preferences.inactiveSchedulingPolicy
    view.configuration.preferences.inactiveSchedulingPolicy = .none
    print(
        "live change: before \(before.rawValue), after \(view.configuration.preferences.inactiveSchedulingPolicy.rawValue); same object: \(view.configuration.preferences === view.configuration.preferences)"
    )
    exit(0)
}
app.run()
