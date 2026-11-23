import SunsetRuntime
import SunsetShell
import SunsetUpdate
import SwiftUI

/// The content of the update dialog: the offer, the notes of every release between, and the buttons.
struct UpdateNotes: View {
    let offer: UpdateOffer
    let close: () -> Void
    @Environment(\.runtime) var runtime
    @State private var updates = AppUpdates.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.m) {
            Text("\(offer.release.title) is available").font(.title2.weight(.semibold))
            Text(
                "You have build \(updates.running.build). What changed since, in \(offer.between.count) "
                    + "release\(offer.between.count == 1 ? "" : "s"):"
            )
            .foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Space.l) {
                    ForEach(offer.between, id: \.build) { release in
                        VStack(alignment: .leading, spacing: Design.Space.s) {
                            Text(release.title).font(.headline)
                            Text(Self.markdown(release.notes)).textSelection(.enabled)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .bouncesOnlyWhenScrolling()
            HStack {
                if let refusal = updates.refusal {
                    Text(refusal.explanation).font(Design.Text.detail).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Later", action: close).keyboardShortcut(.cancelAction)
                button
            }
        }
        .padding(Design.Space.xl)
        .frame(minWidth: 480, minHeight: 360)
    }

    @ViewBuilder private var button: some View {
        switch updates.phase {
            case .ready: Button("Restart to Update") { updates.installAndRestart() }.keyboardShortcut(.defaultAction)
            case .downloading: ProgressView().controlSize(.small)
            default:
                if updates.refusal == nil {
                    Button("Update") { runtime.task { await updates.download(offer) } }.keyboardShortcut(.defaultAction)
                }
        }
    }

    /// The notes as GitHub writes them (Markdown), lines kept.
    static func markdown(_ notes: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: notes, options: options)) ?? AttributedString(notes)
    }
}
