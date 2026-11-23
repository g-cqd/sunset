import SunsetRuntime
import SunsetShell
import SunsetUpdate
import SwiftUI

/// Settings > General > Updates (roadmap 0122, n135): the app and its components, each with its version and where its
/// updates come from; the app's state (up to date, an update found, downloading, ready), a check, and the update.
struct UpdatesCenter: View {
    @Environment(\.runtime) var runtime
    @State private var updates = AppUpdates.shared

    var body: some View {
        LabeledContent {
            HStack(spacing: Design.Space.s) {
                state
                action
            }
        } label: {
            VStack(alignment: .leading, spacing: Design.Space.hair) {
                Text(updates.running.flavour == .webKit ? "Sunset WebKit" : "Sunset")
                Text("\(updates.running.version) (build \(updates.running.build))")
                    .font(Design.Text.detail)
                    .foregroundStyle(.secondary)
            }
        }
        if let refusal = updates.refusal {
            Text(refusal.explanation).font(Design.Text.detail).foregroundStyle(.secondary)
        }
        UpdateComponentRow()
    }

    @ViewBuilder private var state: some View {
        switch updates.phase {
            case .idle: Text(updates.checked == nil ? "Not checked yet" : "").foregroundStyle(.secondary)
            case .checking: ProgressView().controlSize(.small)
            case .upToDate: Label("Up to date", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary)
            case .found(let offer): Text("Build \(offer.release.build) is out").foregroundStyle(.secondary)
            case .downloading: ProgressView().controlSize(.small)
            case .ready(let offer): Text("Build \(offer.release.build) is ready").foregroundStyle(.secondary)
            case .failed(let why): Text(why).font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(2)
        }
    }

    @ViewBuilder private var action: some View {
        switch updates.phase {
            case .found(let offer):
                Button("What\u{2019}s New") { UpdateWindow.show(offer) }
                if updates.refusal == nil { Button("Update") { runtime.task { await updates.download(offer) } } }
            case .ready(let offer):
                Button("What\u{2019}s New") { UpdateWindow.show(offer) }
                Button("Restart to Update") { updates.installAndRestart() }
            case .checking, .downloading:
                EmptyView()
            default:
                Button("Check Now") { runtime.task { await updates.check(manual: true) } }
        }
    }
}
