import AppKit
import SunsetRuntime
import SunsetShell
import SwiftUI

/// Settings > General > Documents > Quick Look: toggles Sunset's bundled Quick Look preview and thumbnail extensions for
/// Markdown and Mermaid files, and links straight to macOS System Settings › Extensions.
struct QuickLookMarkdownRow: View {
    @Environment(\.runtime) private var runtime
    @State private var status = QuickLookExtension.Status(bundled: true, enabled: false, legacyRegistered: false)
    @State private var busy = false

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            LabeledContent("Quick Look for Markdown & Mermaid") {
                HStack(spacing: Design.Space.m) {
                    Toggle(
                        "Quick Look for Markdown & Mermaid",
                        isOn: Binding(
                            get: { status.enabled },
                            set: { next in toggle(next) }
                        )
                    )
                    .settingSwitch()
                    .labelsHidden()
                    .disabled(!status.bundled || busy)
                    Button("System Settings\u{2026}") { QuickLookExtension.openSystemSettings() }
                }
            }
            Text(noteText)
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .task { await refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            runtime.task { await refresh() }
        }
    }

    private var noteText: String {
        if !status.bundled {
            return
                "Available when running the built Sunset.app bundle. Also toggleable in System Settings > General > Login Items & Extensions > Quick Look."
        }
        if status.legacyRegistered {
            return
                "Previews and thumbnails in Finder follow Sunset's Markdown settings below. Turning this on also disables the old MarkdownLook extension."
        }
        return
            "Previews and thumbnails in Finder follow Sunset's Markdown settings below. Also toggleable in System Settings > General > Login Items & Extensions > Quick Look."
    }

    private func refresh() async {
        status = await QuickLookExtension.status()
    }

    private func toggle(_ on: Bool) {
        busy = true
        runtime.task { @MainActor in
            _ = await QuickLookExtension.setEnabled(on)
            status = await QuickLookExtension.status()
            busy = false
        }
    }
}
