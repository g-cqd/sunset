// Loads the web tester's extension into WebKit's own extension host (WKWebExtensionController, macOS 15.4) with every
// permission it asks granted, and starts its background, which probes and saves its results: what a WebKit browser can
// offer extensions with nothing written for them (what Sunset would start from).
// Usage: swift webkit-extension-check.swift <extension folder>
import AppKit
import WebKit

let folder = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Tools/webtester/extension",
    isDirectory: true
)
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)

@MainActor
final class Host {
    let controller = WKWebExtensionController(configuration: .nonPersistent())
    var context: WKWebExtensionContext?

    func start() async {
        do {
            let webExtension = try await WKWebExtension(resourceBaseURL: folder)
            print("loaded:", webExtension.displayName ?? "?", "manifest v\(webExtension.manifestVersion)")
            for error in webExtension.errors {
                print("manifest:", error.localizedDescription)
            }
            let context = WKWebExtensionContext(for: webExtension)
            for permission in webExtension.requestedPermissions {
                context.setPermissionStatus(.grantedExplicitly, for: permission)
            }
            for pattern in webExtension.allRequestedMatchPatterns {
                context.setPermissionStatus(.grantedExplicitly, for: pattern)
            }
            try controller.load(context)
            self.context = context
            context.loadBackgroundContent { error in
                print("background:", error.map { "\($0)" } ?? "started")
            }
        } catch {
            print("failed:", error)
            exit(1)
        }
    }
}

let host = MainActor.assumeIsolated { Host() }
Task { @MainActor in
    await host.start()
}
DispatchQueue.main.asyncAfter(deadline: .now() + 30) { exit(0) }
app.run()
