import SunsetAppCore
import SunsetRuntime
import SunsetShell
import SunsetUpdate
import SwiftUI

/// Settings › General › Updates › Web engine (ADR-0125): one Sunset app, two notarized engine variants (System WebKit vs.
/// Sunset's patched WebKit). Switching downloads the other variant as a delta through the updater and swaps `Sunset.app`
/// cleanly on restart — nothing lives outside the app bundle.
struct UpdateComponentRow: View {
    @Environment(\.runtime) var runtime
    @State private var updates = AppUpdates.shared

    var body: some View {
        LabeledContent {
            HStack(spacing: Design.Space.s) {
                action
            }
        } label: {
            VStack(alignment: .leading, spacing: Design.Space.hair) {
                Text("Web engine")
                Text(detail).font(Design.Text.detail).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var action: some View {
        if updates.refusal != nil {
            EmptyView()
        } else if case .downloading = updates.phase {
            UpdateProgressView(progress: updates.downloadState)
        } else if case .ready = updates.phase, let staged = updates.stagedFlavour, staged != updates.running.flavour {
            Button("Restart to Switch") { updates.installAndRestart() }
        } else {
            let label = updates.running.flavour == .native ? "Switch to Sunset\u{2019}s WebKit" : "Use System WebKit"
            Button(label) { runtime.task { await updates.switchEngine() } }
        }
    }

    private var detail: String {
        if let engine = AppEngineFreshness.engine {
            let age =
                engine.weeks.map { $0 == 0 ? "under a week old, " : "\($0) week\($0 == 1 ? "" : "s") old, " } ?? ""
            return
                "Sunset\u{2019}s WebKit \(engine.base.prefix(12)) (\(age)updated with Sunset). Separate website data from System WebKit."
        }
        return "System WebKit (updated by macOS). Switch to Sunset\u{2019}s WebKit for patches and extensions."
    }
}
