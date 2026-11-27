import Foundation
import SunsetRuntime
import SunsetShell
import SunsetUpdate
import SwiftUI

/// An update in the sidebar, as a Now Playing card is (the owner's note n151): one found offers Download, one ready
/// offers Restart to Update; What's New opens its notes, and the card can be put away until the next build.
struct UpdateCard: View {
    let updates: AppUpdates
    let surface: AnyView
    @Environment(\.surfaceStyle) private var style
    @AppStorage("updates.cardDismissed") private var dismissed = 0

    /// Whether a card is shown now: an update found or ready, not put away for its build.
    @MainActor static func isShown(_ updates: AppUpdates) -> Bool {
        guard let shown = shown(updates.phase) else { return false }
        return UserDefaults.standard.integer(forKey: "updates.cardDismissed") != shown.offer.release.build
    }

    private var shown: (offer: UpdateOffer, ready: Bool, downloading: Bool)? {
        Self.shown(updates.phase)
    }

    /// The offer to show, and whether it is ready to install.
    private static func shown(_ phase: AppUpdates.Phase) -> (offer: UpdateOffer, ready: Bool, downloading: Bool)? {
        switch phase {
            case .found(let offer): (offer, false, false)
            case .downloading(let offer): (offer, false, true)
            case .ready(let offer): (offer, true, false)
            default: nil
        }
    }

    var body: some View {
        if let shown, dismissed != shown.offer.release.build {
            let shape = RoundedRectangle(cornerRadius: Design.NowPlaying.radius, style: .continuous)
            VStack(alignment: .leading, spacing: Design.Space.s) {
                HStack(spacing: Design.Space.s) {
                    Image(systemName: shown.ready ? "arrow.clockwise.circle.fill" : "arrow.down.circle.fill")
                        .font(Design.Text.body)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: Design.Space.hair) {
                        Text(shown.ready ? "Update ready" : "Update available").font(Design.Text.body.weight(.semibold))
                        Text(shown.offer.release.tag).font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Not Now", systemImage: "xmark") { dismissed = shown.offer.release.build }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                }
                HStack {
                    Button("What\u{2019}s New") { UpdateWindow.show(shown.offer) }.buttonStyle(.borderless)
                    Spacer(minLength: 0)
                    if shown.ready {
                        Button("Restart to Update") { updates.installAndRestart() }.buttonStyle(.borderedProminent)
                    } else if shown.downloading {
                        ProgressView().controlSize(.small)
                    } else {
                        Button("Download") {
                            let offer = shown.offer
                            Runtime.live.task { @MainActor in await updates.download(offer) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .controlSize(.small)
            }
            .padding(Design.NowPlaying.inset)
            .background { surface.clipShape(shape) }
            .clipShape(shape)
            .overlay { shape.hairline(style.layout) }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(shown.ready ? "Update ready" : "Update available")
        }
    }
}
