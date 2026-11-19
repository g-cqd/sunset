// Whether a page in a WKWebView can begin an Apple Pay session from a click, with and without a user script injected
// (WebKit, 2019: "Apple Pay cannot be used alongside of script injection APIs"). The page reports through a message
// handler; the click is a real mouse event sent to the view; the session is aborted at once (2026-11-19).
import AppKit
import WebKit

let page = """
    <button id=b style="position:fixed;left:0;top:0;width:300px;height:200px">pay</button>
    <script>
    const say = (m) => webkit.messageHandlers.r.postMessage(m);
    say("loaded: ApplePaySession " + ("ApplePaySession" in window));
    b.onclick = () => {
      try {
        const s = new ApplePaySession(3, { countryCode: "US", currencyCode: "USD", supportedNetworks: ["visa", "masterCard"],
          merchantCapabilities: ["supports3DS"], total: { label: "Probe", amount: "1.00" } });
        s.onvalidatemerchant = () => { say("validatemerchant asked (the sheet is up)"); s.abort(); };
        s.oncancel = () => say("cancelled");
        s.begin();
        say("begun");
        setTimeout(() => { try { s.abort(); say("aborted"); } catch (e) { say("abort: " + e.name + ": " + e.message); } }, 1500);
      } catch (e) { say("begin threw " + e.name + ": " + e.message); }
    };
    </script>
    """

@MainActor final class Probe: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    var label = ""
    var loaded: (() -> Void)?
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        print(label, "|", m.body)
        if (m.body as? String)?.hasPrefix("loaded") == true { loaded?() }
    }
}

@MainActor func make(script: Bool, probe: Probe) -> (NSWindow, WKWebView) {
    let c = WKWebViewConfiguration()
    let t = type(of: c.preferences) as AnyObject as? NSObject ?? NSObject()
    let setter = NSSelectorFromString("_setEnabled:forFeature:")
    typealias Setter = @convention(c) (NSObject, Selector, Bool, NSObject) -> Void
    let call = unsafeBitCast(c.preferences.method(for: setter), to: Setter.self)
    for f in t.value(forKey: "_features") as? [NSObject] ?? []
    where (f.value(forKey: "key") as? String) == "ApplePayEnabled" {
        call(c.preferences, setter, true, f)
    }
    c.userContentController.add(probe, name: "r")
    if script {
        c.userContentController.addUserScript(
            WKUserScript(source: "window.injected = 1", injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
    }
    let w = NSWindow(
        contentRect: .init(x: 40, y: 40, width: 300, height: 200),
        styleMask: [.titled],
        backing: .buffered,
        defer: false
    )
    let v = WKWebView(frame: w.contentView?.bounds ?? .zero, configuration: c)
    w.contentView?.addSubview(v)
    w.makeKeyAndOrderFront(nil)
    return (w, v)
}

@MainActor func click(_ w: NSWindow) {
    let at = NSPoint(x: 150, y: 100)
    for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
        guard
            let e = NSEvent.mouseEvent(
                with: type,
                location: at,
                modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: w.windowNumber,
                context: nil,
                eventNumber: 0,
                clickCount: 1,
                pressure: 1
            )
        else { continue }
        w.sendEvent(e)
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    app.activate(ignoringOtherApps: true)
    var keep: [AnyObject] = []
    @MainActor func run(_ cases: [(String, Bool)]) {
        guard let (label, script) = cases.first else {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in exit(0) }
            return
        }
        let probe = Probe()
        probe.label = label
        let (w, v) = make(script: script, probe: probe)
        keep += [w, v, probe]
        probe.loaded = {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { @MainActor _ in
                MainActor.assumeIsolated { click(w) }
                Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { @MainActor _ in
                    MainActor.assumeIsolated {
                        w.orderOut(nil)
                        run(Array(cases.dropFirst()))
                    }
                }
            }
        }
        v.loadHTMLString(page, baseURL: URL(string: "https://shop.example/"))
    }
    run([("no script", false), ("a user script", true)])
    app.run()
}
