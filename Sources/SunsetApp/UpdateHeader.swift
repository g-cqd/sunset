import AppKit
import SunsetRuntime
import SunsetShell
import SunsetShellModel
import SunsetUpdate
import SwiftUI

/// The update window's top: Sunset's sky as a band, the app's icon, what is offered and what the person has.
struct UpdateHeader: View {
    let offer: UpdateOffer
    let running: RunningApp
    let state: String
    /// The release's title as the window may show it (`NotesCheck.title`).
    var title: String

    var body: some View {
        HStack(spacing: Design.Space.xl) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: Design.Update.icon, height: Design.Update.icon)
                .shadow(color: .black.opacity(Design.Shadow.popover.opacity), radius: Design.Shadow.popover.radius)
            VStack(alignment: .leading, spacing: Design.Space.xs) {
                Text(state).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                Text(title).font(.title.bold())
                Text(verbatim: "You have \(running.version) (build \(running.build))")
                    .font(Design.Text.secondary)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Design.Update.margin)
        .frame(maxWidth: .infinity, minHeight: Design.Update.header, maxHeight: Design.Update.header)
        .background {
            ZStack {
                SunsetSkyView { _, size in SunsetSkyFrame.window(size, preset: SkyPreset.at(Runtime.live.now())) }
                LinearGradient(
                    colors: [.black.opacity(Design.Update.dimming), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .environment(\.colorScheme, .dark)
    }
}
