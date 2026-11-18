// Run: swiftc -O -o /tmp/titlebar Scripts/probes/webkit-titlebar-inset.swift && /tmp/titlebar (roadmap 0045 D, 2026-11-18).
// Does a WKWebView that reaches the top of a window with a full-size content view and a transparent title bar (Sunset's
// window with no decorations) lay its page out below the title bar, leaving a band at the top? Read where the page's
// first pixel row is (`elementFromPoint`) and WebKit's insets, at the window's top and inset from it (a docked card).
import AppKit
import WebKit

@MainActor func run(_ name: String, top: Double) async {
    let window = NSWindow(
        contentRect: CGRect(x: 0, y: 0, width: 800, height: 600),
        styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
        backing: .buffered,
        defer: false
    )
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.isReleasedWhenClosed = false
    let content = NSView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
    window.contentView = content
    let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600 - top))
    content.addSubview(view)
    window.orderBack(nil)
    view.loadHTMLString(
        "<body style='margin:0'><div id='top' style='height:100px;background:red'>top</div></body>",
        baseURL: URL(string: "https://example.com/")
    )
    while view.isLoading || view.estimatedProgress < 1 { try? await Task.sleep(for: .milliseconds(50)) }
    try? await Task.sleep(for: .milliseconds(300))
    let read =
        (try? await view.evaluateJavaScript(
            "[innerHeight, document.getElementById('top').getBoundingClientRect().top, (document.elementFromPoint(5, 5) || {}).id || 'none'].join(' ')"
        ) as? String) ?? "?"
    let insets = view.obscuredContentInsets
    print("\(name): innerHeight top-of-div element-at-5 = \(read); obscuredContentInsets top \(insets.top)")
    window.close()
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
Task { @MainActor in
    await run("at the window's top", top: 0)
    await run("16 below the top", top: 16)
    exit(0)
}
app.run()
