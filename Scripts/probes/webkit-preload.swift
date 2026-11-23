// Roadmap 0113 step A: can a process that does not link WebKit load a WebKit from a folder chosen at run time, with no
// loader variables, so that everything after (system frameworks that link WebKit included) binds to it?
//
//   swiftc -O Scripts/probes/webkit-preload.swift -o /tmp/webkit-preload
//   /tmp/webkit-preload FRAMEWORKS [page]
//
// FRAMEWORKS: a folder of WebKit's frameworks (Sunset WebKit.app/Contents/Frameworks, or a copy of it elsewhere). With
// `page`, a web view loads a page and prints the user agent (needs WebKit's processes: see the diary).
// It prints every WebKit image in the process: before, after the preload, after system frameworks that link WebKit.
import AppKit
import Foundation
import MachO

func webKitImages() -> [String] {
    let names = [
        "/WebKit.framework/", "/WebCore.framework/", "/JavaScriptCore.framework/", "/WebKitLegacy.framework/",
        "/WebGPU.framework/", "libwebrtc", "libANGLE"
    ]
    return (0 ..< _dyld_image_count())
        .compactMap { index in
            guard let name = _dyld_get_image_name(index) else { return nil }
            let path = String(cString: name)
            return names.contains { path.contains($0) } ? path : nil
        }
}

func show(_ title: String) {
    print("== \(title)")
    for image in webKitImages() { print("   \(image)") }
}

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    print("usage: webkit-preload FRAMEWORKS [page]")
    exit(64)
}
let folder = arguments[1]
show("at start")
// Leaves first: each one's dependents already in the process when it is loaded.
let order = [
    "libwebrtc.dylib", "libANGLE-shared.dylib", "JavaScriptCore.framework/JavaScriptCore",
    "WebGPU.framework/WebGPU", "WebCore.framework/WebCore", "WebKitLegacy.framework/WebKitLegacy",
    "WebKit.framework/WebKit"
]
for item in order {
    let path = folder + "/" + item
    guard FileManager.default.fileExists(atPath: path) else { continue }
    if dlopen(path, RTLD_NOW | RTLD_GLOBAL) == nil {
        print("dlopen \(item): \(String(cString: dlerror()))")
        exit(1)
    }
}
show("after the preload")
// The system frameworks to load next, each on its own: $PROBE_SYSTEM (comma separated), else the system's WebKit path.
let systems = (ProcessInfo.processInfo.environment["PROBE_SYSTEM"] ?? "WebKit").split(separator: ",").map(String.init)
for system in systems {
    let path = system.hasPrefix("/") ? system : "/System/Library/Frameworks/\(system).framework/\(system)"
    if dlopen(path, RTLD_NOW) == nil { print("dlopen \(system): \(String(cString: dlerror()))") }
    print("after \(system): \(webKitImages().filter { $0.hasPrefix("/System") }.count) of the system's WebKit images")
}
let webView: AnyClass? = NSClassFromString("WKWebView")
print("WKWebView from: \(webView.map { Bundle(for: $0).bundlePath } ?? "none")")
guard arguments.count >= 3, let viewType = webView as? NSView.Type else { exit(0) }

// A page: the user agent, or the failure, within 20 seconds.
_ = NSApplication.shared
let view = viewType.init(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
let script = Selector(("evaluateJavaScript:completionHandler:"))
let load = Selector(("loadHTMLString:baseURL:"))
// $PROBE_PAGE: the page's HTML (a form, a video…), to see what WebKit loads for it.
let beforePage = Set((0 ..< _dyld_image_count()).compactMap { _dyld_get_image_name($0).map { String(cString: $0) } })
let html = ProcessInfo.processInfo.environment["PROBE_PAGE"] ?? "<p>probe</p>"
_ = view.perform(load, with: html, with: URL(string: "https://example.com/"))
var answered = false
let deadline = Date().addingTimeInterval(20)
RunLoop.main.run(
    until: Date().addingTimeInterval(Double(ProcessInfo.processInfo.environment["PROBE_HOLD"] ?? "2") ?? 2)
)
let handler: @convention(block) (AnyObject?, NSError?) -> Void = { value, error in
    print("page: \(value.map { "\($0)" } ?? "nil") \(error.map { "error \($0)" } ?? "")")
    answered = true
}
_ = view.perform(
    script,
    with: ProcessInfo.processInfo.environment["PROBE_SCRIPT"] ?? "navigator.userAgent",
    with: handler
)
while !answered && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.2)) }
if !answered { print("page: no answer in 20 s") }
show("after the page")
if ProcessInfo.processInfo.environment["PROBE_ALL"] != nil {
    let after = (0 ..< _dyld_image_count()).compactMap { _dyld_get_image_name($0).map { String(cString: $0) } }
    for image in after where !beforePage.contains(image) { print("new: \(image)") }
}
print("system WebKit images after the page: \(webKitImages().filter { $0.hasPrefix("/System") }.count)")
