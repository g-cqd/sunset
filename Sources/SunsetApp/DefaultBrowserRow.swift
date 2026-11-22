import AppKit
import SunsetRuntime
import SunsetShell
import SwiftUI

/// Settings > Web > Pages: whether Sunset is the Mac's browser, and a button to make it so. macOS asks the person to
/// confirm; the answer is read again when Sunset comes back to the front.
struct DefaultBrowserRow: View {
    @Environment(\.runtime) var runtime

    @State private var isDefault = DefaultBrowserRow.sunsetIsDefault()
    @State private var failed = false

    var body: some View {
        LabeledContent("Default browser") {
            if isDefault {
                Label("Sunset", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary)
            } else {
                Button("Make Sunset the Default Browser") { makeDefault() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            isDefault = Self.sunsetIsDefault()
        }
        if failed {
            Text("macOS did not change it. System Settings > Desktop & Dock > Default web browser.")
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
        }
    }

    /// Whether the app macOS opens web links with is this one.
    static func sunsetIsDefault() -> Bool {
        guard let probe = URL(string: "https://example.org"),
            let handler = NSWorkspace.shared.urlForApplication(toOpen: probe)
        else { return false }
        return handler.resolvingSymlinksInPath() == Bundle.main.bundleURL.resolvingSymlinksInPath()
    }

    private func makeDefault() {
        runtime.task { @MainActor in
            failed = await !Self.makeSunsetDefault()
            isDefault = Self.sunsetIsDefault()
        }
    }

    /// Asks macOS to open web links with Sunset (it asks the person to confirm); false when it refused.
    static func makeSunsetDefault() async -> Bool {
        let app = Bundle.main.bundleURL
        var refused = false
        for scheme in ["http", "https"] {
            do {
                try await NSWorkspace.shared.setDefaultApplication(at: app, toOpenURLsWithScheme: scheme)
            } catch {
                refused = true
            }
        }
        return !refused
    }
}
