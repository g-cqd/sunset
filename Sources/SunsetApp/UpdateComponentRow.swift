import SunsetAppCore
import SunsetRuntime
import SunsetShell
import SunsetUpdate
import SwiftUI

/// The update centre's web engine (roadmap 0113, the owner): for the native app, the system's WebKit or Sunset's own
/// beside it, to download, use or not, delete, and update; each change made when Sunset next opens. Sunset WebKit has its
/// own inside it, updated with the app.
struct UpdateComponentRow: View {
    @Environment(\.runtime) var runtime
    @State private var engine = AppEngine.shared

    var body: some View {
        LabeledContent {
            HStack(spacing: Design.Space.s) {
                if engine.available { actions }
            }
        } label: {
            VStack(alignment: .leading, spacing: Design.Space.hair) {
                Text("Web engine")
                Text(detail).font(Design.Text.detail).foregroundStyle(.secondary)
            }
        }
        if engine.changesAtRestart {
            HStack {
                Text("Changes when Sunset opens again.").font(Design.Text.detail).foregroundStyle(.secondary)
                Spacer()
                Button("Restart Now") { AppUpdates.shared.restart() }
            }
        }
        if case .failed(let why) = engine.phase {
            Text(why).font(Design.Text.detail).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var actions: some View {
        if engine.phase == .downloading {
            ProgressView().controlSize(.small)
        } else if let offer = engine.offer {
            Button(engine.installed == nil ? "Download (\(Self.size(offer)))" : "Update (\(Self.size(offer)))") {
                runtime.task { await engine.download() }
            }
        }
        if engine.installed != nil || engine.staged != nil, !engine.removing {
            Toggle("Use it", isOn: use).settingSwitch()
            Button("Delete\u{2026}", role: .destructive) { engine.remove() }
        }
    }

    /// Whether the engine is to be used from the next start.
    private var use: Binding<Bool> {
        Binding(
            get: { engine.wantsEngine ?? (engine.place.state == .on) },
            set: { engine.wantsEngine = $0 }
        )
    }

    private var detail: String {
        guard engine.available else {
            return AppEngineFreshness.engine.map {
                "Sunset\u{2019}s WebKit \($0.base.prefix(12)), updated with the app"
            }
                ?? "The system\u{2019}s WebKit, updated by macOS"
        }
        let now: String
        switch engine.runningOn {
            case .engine: now = "In use: Sunset\u{2019}s WebKit"
            case .system: now = "In use: the system\u{2019}s WebKit"
            case .mixed: now = "In use: an incomplete engine"
        }
        guard let installed = engine.installed else { return now + ". Sunset\u{2019}s own is not downloaded." }
        return now + ". Sunset\u{2019}s, build \(installed.build), is "
            + (engine.removing ? "to be deleted." : "installed.")
    }

    private static func size(_ offer: UpdateOffer) -> String {
        Int64(offer.archive.size).formatted(.byteCount(style: .file))
    }
}
