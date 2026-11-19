// t114: can Sunset seal WebKit's cookie jars at quit and put them back at launch? (2026-11-19)
//   jarprobe write   : a lasting cookie in the default store and in a profile store, a page loaded in each (the network
//                      process up), flushed; both jars moved aside (`.moved`), as sealing would; then the app quits.
//                      The shell then looks whether WebKit writes a jar again after the app has gone.
//   jarprobe read    : the jars put back by the shell before any store opens; are the cookies read?
import AppKit
import WebKit

let profile = UUID(uuid: (0x6E, 0x1F, 0x4C, 0x2A, 0, 0, 0x40, 0, 0x80, 0, 0, 0, 0, 0, 0xA0, 0x01))
let library = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library")
let name = ProcessInfo.processInfo.processName
let jars = [
    library.appending(path: "HTTPStorages/\(name).binarycookies"),
    library.appending(path: "WebKit/\(name)/WebsiteDataStore/\(profile.uuidString)/Cookies/Cookies.binarycookies")
]

@MainActor final class Loader: NSObject, WKNavigationDelegate {
    var done: CheckedContinuation<Void, Never>?
    func webView(_ w: WKWebView, didFinish n: WKNavigation!) { finish() }
    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: any Error) { finish() }
    func finish() {
        done?.resume()
        done = nil
    }
}

@MainActor func flush(_ store: WKHTTPCookieStore) async {
    let selector = NSSelectorFromString("_flushCookiesToDiskWithCompletionHandler:")
    typealias Flush = @convention(c) (AnyObject, Selector, @escaping @convention(block) () -> Void) -> Void
    let call = unsafeBitCast(store.method(for: selector), to: Flush.self)
    await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in call(store, selector) { done.resume() }
    }
}

func describe(_ url: URL) -> String {
    let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
    guard let size = attributes?[.size] as? Int, let mode = attributes?[.posixPermissions] as? Int else {
        return "absent"
    }
    return "\(size) B, mode \(String(mode, radix: 8))"
}

final class Delegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        print("willTerminate: jars", jars.map(describe))
    }
}

MainActor.assumeIsolated {
    let delegate = Delegate()
    NSApplication.shared.delegate = delegate
    Task { @MainActor in
        let stores = [WKWebsiteDataStore.default(), WKWebsiteDataStore(forIdentifier: profile)]
        if CommandLine.arguments.dropFirst().first == "read" {
            for (index, store) in stores.enumerated() {
                let cookies = await store.httpCookieStore.allCookies().filter { $0.name == "jarprobe" }
                print("read store \(index): \(cookies.map(\.value))")
            }
            exit(0)
        }
        var views: [WKWebView] = []
        for (index, store) in stores.enumerated() {
            guard
                let cookie = HTTPCookie(properties: [
                    .name: "jarprobe", .value: "kept-\(index)", .domain: "jar.example", .path: "/",
                    .expires: Date(timeIntervalSinceNow: 86_400), .secure: true
                ])
            else { continue }
            await store.httpCookieStore.setCookie(cookie)
            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = store
            let view = WKWebView(frame: .zero, configuration: configuration)
            let loader = Loader()
            view.navigationDelegate = loader
            await withCheckedContinuation {
                loader.done = $0
                view.loadHTMLString("<p>x</p>", baseURL: URL(string: "https://jar.example/"))
            }
            views.append(view)
            await flush(store.httpCookieStore)
        }
        print("flushed: jars", jars.map(describe))
        for jar in jars where FileManager.default.fileExists(atPath: jar.path) {
            let moved = jar.appendingPathExtension("moved")
            try? FileManager.default.removeItem(at: moved)
            try? FileManager.default.moveItem(at: jar, to: moved)
        }
        print("moved aside: jars", jars.map(describe))
        withExtendedLifetime(views) { NSApp.terminate(nil) }
    }
    NSApplication.shared.run()
}
