import SunsetRuntime
import SunsetShell
import SunsetUpdate
import SwiftUI

/// The update window's content (n135): the sky's band with the offer, the notes of every release between the running
/// build and it, then where the update is and its buttons, as the welcome's.
struct UpdateNotes: View {
    let offer: UpdateOffer
    let close: () -> Void
    @Environment(\.runtime) var runtime
    @State private var updates = AppUpdates.shared

    var body: some View {
        VStack(spacing: 0) {
            UpdateHeader(
                offer: offer,
                running: updates.running,
                state: state,
                title: (updates.notesChecks[offer.release.build] ?? .unsigned)
                    .title(given: offer.release.title, build: offer.release.build)
            )
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Space.xxl) {
                    ForEach(offer.between, id: \.build) { release in
                        ReleaseNotesView(
                            release: release,
                            showsTitle: offer.between.count > 1,
                            check: updates.notesChecks[release.build]
                        )
                    }
                }
                .frame(maxWidth: Design.Update.column, alignment: .leading)
                .padding(Design.Update.margin)
                .frame(maxWidth: .infinity)
            }
            .bouncesOnlyWhenScrolling()
            Divider()
            footer
        }
        .frame(width: Design.Update.size.width, height: Design.Update.size.height)
        .ignoresSafeArea()
        .animation(Design.Update.change, value: updates.phase)
    }

    private var footer: some View {
        HStack(spacing: Design.Space.l) {
            note
            Spacer()
            Button("Later", action: close).buttonStyle(.glass).keyboardShortcut(.cancelAction)
            button
        }
        .controlSize(.large)
        .padding(.horizontal, Design.Update.margin)
        .padding(.vertical, Design.Space.xl)
    }

    /// The line beside the buttons: why it cannot install, the download's size, an error, or when it goes in.
    @ViewBuilder private var note: some View {
        Group {
            if let refusal = updates.refusal {
                Text(refusal.explanation)
            } else if case .failed(let why) = updates.phase {
                Text(why).foregroundStyle(.red)
            } else if case .ready = updates.phase {
                Text(updates.settings.automatic ? "Installed when Sunset quits, or now." : "Ready to install.")
            } else if case .downloading = updates.phase {
                UpdateProgressView(progress: updates.downloadState)
            } else {
                Text("\(download.formatted(.byteCount(style: .file))) to download")
            }
        }
        .font(Design.Text.secondary)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }

    @ViewBuilder private var button: some View {
        switch updates.phase {
            case .ready:
                Button("Restart to Update") { updates.installAndRestart() }
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
            case .downloading:
                Button("Updating\u{2026}") {}
                    .buttonStyle(.glassProminent)
                    .disabled(true)
            case .failed:
                Button("Try Again") { runtime.task { await updates.download(offer) } }
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(updates.refusal != nil)
            default:
                Button("Update") { runtime.task { await updates.download(offer) } }
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(updates.refusal != nil)
        }
    }

    /// What the header says of it.
    private var state: String {
        switch updates.phase {
            case .ready: "Ready to install"
            case .downloading:
                switch updates.downloadState?.stage ?? .downloading {
                    case .preparing: "Preparing\u{2026}"
                    case .downloading: "Downloading\u{2026}"
                    case .installing: "Preparing update\u{2026}"
                    case .verifying: "Verifying\u{2026}"
                }
            case .failed: "Update failed"
            default: "A new Sunset is available"
        }
    }

    /// The bytes to fetch: the package from the running build when there is one, else the archive.
    private var download: Int64 {
        let package = offer.release.package(
            for: updates.running.flavour,
            from: updates.running.build,
            architecture: RunningApp.architecture
        )
        return Int64(package?.size ?? offer.archive.size)
    }
}
