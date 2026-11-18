// Run: swiftc -O -o /tmp/rehost Scripts/probes/webkit-rehost-scroll.swift && /tmp/rehost (roadmap 0045 A, 2026-11-18).
// Does a page keep its scroll positions (the document's, an inner scroller's, a horizontal one's) when its WKWebView is
// taken out of its window and put back in a new host, as `WebViewHost` does when a tab is shown again? Once with the
// view given the host's zero frame first (as `place(in:)` does), once at its own size, and once with a turn of the
// run loop at zero size.
import AppKit
import WebKit

let page = """
    <html><body style="margin:0">
    <div id="inner" style="position:fixed;right:0;top:0;width:300px;height:300px;overflow:auto">
      <div style="height:5000px;background:linear-gradient(red,blue)">inner</div></div>
    <div id="wide" style="position:fixed;left:0;bottom:0;width:300px;overflow-x:auto;white-space:nowrap">
      \(String(repeating: "wide text ", count: 400))</div>
    \((0..<400).map { "<p>Paragraph \($0) with enough words to wrap when the page is narrow, and more words.</p>" }.joined())
    </body></html>
    """

@MainActor func positions(_ view: WKWebView) async -> String {
    // Not a frame callback: a window behind others may draw none.
    try? await Task.sleep(for: .milliseconds(400))
    let script = """
        [scrollY, document.getElementById('inner').scrollTop, document.getElementById('wide').scrollLeft,
         innerWidth].join(' ')
        """
    return (try? await view.evaluateJavaScript(script) as? String) ?? "?"
}

@MainActor func run(_ name: String, zeroFirst: Bool, turn: Bool, interim: CGRect? = nil) async {
    let frame = CGRect(x: 0, y: 0, width: 900, height: 700)
    let window = NSWindow(contentRect: frame, styleMask: [.titled], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    let content = NSView(frame: frame)
    window.contentView = content
    window.orderBack(nil)
    let view = WKWebView(frame: frame)
    view.autoresizingMask = [.width, .height]
    content.addSubview(view)
    view.loadHTMLString(page, baseURL: URL(string: "https://example.com/"))
    while view.isLoading || view.estimatedProgress < 1 { try? await Task.sleep(for: .milliseconds(50)) }
    _ = try? await view.evaluateJavaScript(
        "scrollTo(0, 4000); document.getElementById('inner').scrollTop = 2000;"
            + " document.getElementById('wide').scrollLeft = 1500; 0"
    )
    let before = await positions(view)
    // Hidden: out of the window, as a tab switched away from.
    view.removeFromSuperview()
    try? await Task.sleep(for: .milliseconds(500))
    // Shown again in a new host, laid out after.
    let host = NSView(frame: .zero)
    content.addSubview(host)
    view.frame = zeroFirst ? host.bounds : frame
    view.autoresizingMask = zeroFirst ? [.width, .height] : []
    host.addSubview(view)
    if turn { try? await Task.sleep(for: .milliseconds(100)) }
    // Laid out at another size first, for a turn (an animated frame), when asked.
    if let other = interim {
        host.frame = other
        if !zeroFirst { view.frame = host.bounds }
        try? await Task.sleep(for: .milliseconds(300))
    }
    host.frame = frame
    if !zeroFirst { view.frame = host.bounds }
    let after = await positions(view)
    print("\(name): before \(before) | after \(after)")
    window.close()
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
Task { @MainActor in
    print("scrollY innerTop wideLeft innerWidth")
    await run("zero frame first, same turn", zeroFirst: true, turn: false)
    await run("zero frame first, a turn at zero", zeroFirst: true, turn: true)
    await run("own size", zeroFirst: false, turn: false)
    await run(
        "half width for a moment",
        zeroFirst: false,
        turn: false,
        interim: CGRect(x: 0, y: 0, width: 450, height: 700)
    )
    await run("tiny for a moment", zeroFirst: false, turn: false, interim: CGRect(x: 0, y: 0, width: 40, height: 40))
    exit(0)
}
app.run()
