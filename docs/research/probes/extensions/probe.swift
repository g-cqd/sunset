import AppKit
import WebKit

final class Tab: NSObject, WKWebExtensionTab {
    weak var view: WKWebView?
    init(_ view: WKWebView) { self.view = view }
    func webView(for context: WKWebExtensionContext) -> WKWebView? { view }
}

// Loads the unpacked extension in hello/, grants what it asks, opens a page, reads what the content script and the worker did.
MainActor.assumeIsolated {
    _ = NSApplication.shared
    let semaphore = DispatchSemaphore(value: 0)
    Task { @MainActor in
        defer { semaphore.signal() }
        do {
            let ext = try await WKWebExtension(
                resourceBaseURL: URL(fileURLWithPath: "/tmp/ext/hello", isDirectory: true)
            )
            print(
                "loaded:",
                ext.displayName ?? "-",
                "v",
                ext.version ?? "-",
                "errors:",
                ext.errors.map(\.localizedDescription)
            )
            print(
                "asks:",
                ext.requestedPermissions.map(\.rawValue).sorted(),
                ext.requestedPermissionMatchPatterns.map(\.string)
            )
            let context = WKWebExtensionContext(for: ext)
            for p in ext.requestedPermissions { context.setPermissionStatus(.grantedExplicitly, for: p) }
            if ProcessInfo.processInfo.environment["DENY"] == nil {
                for m in ext.requestedPermissionMatchPatterns {
                    context.setPermissionStatus(.grantedExplicitly, for: m)
                }
            }
            let controller = WKWebExtensionController(configuration: .nonPersistent())
            try controller.load(context)
            let config = WKWebViewConfiguration()
            config.webExtensionController = controller
            let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 400, height: 300), configuration: config)
            let tab = Tab(view)
            controller.didOpenTab(tab)
            guard let page = URL(string: "http://127.0.0.1:8799/other.html") else { return }
            view.load(URLRequest(url: page))
            for _ in 0 ..< 60 {
                try await Task.sleep(for: .milliseconds(100))
                if let w = try? await view.evaluateJavaScript("document.documentElement.dataset.worker"), w is String {
                    break
                }
            }
            let ran = try? await view.evaluateJavaScript("document.documentElement.dataset.ext ?? 'none'")
            let worker = try? await view.evaluateJavaScript("document.documentElement.dataset.worker ?? 'none'")
            print("content:", ran ?? "nil", "worker:", worker ?? "nil")
            _ = tab
        } catch { print("failed:", error) }
    }
    while semaphore.wait(timeout: .now()) == .timedOut { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05)) }
}
