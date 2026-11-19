// What WebAuthn answers a page in a WKWebView of an app without the browser entitlement, from a real click; aborted after 1.5 s (2026-11-19).
import AppKit
import WebKit

let page = """
    <button id=b style="position:fixed;left:0;top:0;width:300px;height:200px">key</button>
    <script>
    const say = (m) => webkit.messageHandlers.r.postMessage(m);
    say("loaded: focused " + document.hasFocus());
    b.onclick = async () => {
      const stop = new AbortController();
      setTimeout(() => stop.abort(), 1500);
      const t0 = performance.now();
      for (const [label, publicKey] of [
        ["create, platform", { rp: { name: "x", id: "shop.example" }, user: { id: new Uint8Array(8), name: "a", displayName: "a" },
          challenge: new Uint8Array(16), pubKeyCredParams: [{ type: "public-key", alg: -7 }], authenticatorSelection: { authenticatorAttachment: "platform" } }],
      ]) {
        try { await navigator.credentials.create({ publicKey, signal: stop.signal }); say(label + ": made"); }
        catch (e) { say(label + ": " + e.name + ": " + e.message + " after " + Math.round(performance.now() - t0) + " ms"); }
      }
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
    where (f.value(forKey: "key") as? String) == "NoSuchFeature" {
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
                Timer.scheduledTimer(withTimeInterval: 12, repeats: false) { @MainActor _ in
                    MainActor.assumeIsolated {
                        w.orderOut(nil)
                        run(Array(cases.dropFirst()))
                    }
                }
            }
        }
        v.loadHTMLString(page, baseURL: URL(string: "https://shop.example/"))
    }
    run([("WebAuthn, ad hoc signed, no entitlement", false)])
    app.run()
}
