// Opens a URL in a bare WKWebView and keeps it open long enough for the tester's automatic tests to run and save their
// results: the engine Safari and Sunset share, with nothing of either (no policy, no prompts answered).
// Usage: swift webkit-check.swift URL
import AppKit
import WebKit

let address = CommandLine.arguments.dropFirst().first ?? "http://localhost:8767/index.html?browser=webkit&auto=1"
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let configuration = WKWebViewConfiguration()
let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 1200, height: 900), configuration: configuration)
let window = NSWindow(contentRect: view.frame, styleMask: [.titled], backing: .buffered, defer: false)
window.contentView = view
// Off screen: a page shown nowhere is throttled the less for being in a window.
window.setFrameOrigin(NSPoint(x: -4000, y: -4000))
window.orderBack(nil)
if let url = URL(string: address) {
    view.load(URLRequest(url: url))
}
DispatchQueue.main.asyncAfter(deadline: .now() + 45) { exit(0) }
app.run()
