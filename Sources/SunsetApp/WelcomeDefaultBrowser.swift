import AppKit
import SunsetRuntime
import SunsetShell
import SwiftUI

/// The welcome's browser question: whether Sunset is the browser, and a button that asks macOS (which asks the person).
struct WelcomeDefaultBrowser: View {
    @Environment(\.runtime) private var runtime
    @State private var isDefault = DefaultBrowserRow.sunsetIsDefault()
    @State private var refused = false

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Welcome.row) {
            if isDefault {
                Label("Sunset opens your links.", systemImage: "checkmark.circle.fill").font(.body.weight(.medium))
            } else {
                Button("Make Sunset the Default Browser") {
                    runtime.task { @MainActor in
                        refused = await !DefaultBrowserRow.makeSunsetDefault()
                        isDefault = DefaultBrowserRow.sunsetIsDefault()
                    }
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                Text("Or Continue to leave it as it is.").font(.callout).foregroundStyle(.secondary)
            }
            if refused {
                Text("macOS did not change it. System Settings \u{25B8} Desktop & Dock \u{25B8} Default web browser.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            isDefault = DefaultBrowserRow.sunsetIsDefault()
        }
    }
}
