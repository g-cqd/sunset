import SunsetRuntime
import SunsetShell
import SunsetWebModel
import SwiftUI

/// One Now Playing card (roadmap 0114): what plays and where, and its controls: previous, play or pause, next, mute,
/// picture in picture for a video, and the way to its tab.
struct NowPlayingCard: View {
    let page: MediaPage
    let center: NowPlaying
    let pictureInPicture: Bool
    let goThere: (WebContent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            HStack(spacing: Design.Space.m) {
                picture
                VStack(alignment: .leading, spacing: Design.Space.hair) {
                    Text(page.title).font(Design.Text.body).lineLimit(1)
                    Text(page.artist ?? page.host).font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: Design.Space.xs) {
                control("backward.fill", "Previous") { await center.skip(page.id, forward: false) }
                control(page.isPlaying ? "pause.fill" : "play.fill", page.isPlaying ? "Pause" : "Play") {
                    await center.togglePlaying(page.id)
                }
                control("forward.fill", "Next") { await center.skip(page.id, forward: true) }
                Spacer(minLength: 0)
                control(page.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill", page.isMuted ? "Unmute" : "Mute") {
                    center.toggleMuted(page.id)
                }
                if pictureInPicture, page.hasVideo {
                    control("pip.enter", "Picture in Picture") { center.pictureInPicture(page.id) }
                }
                control("arrow.up.forward.square", "Go to Its Tab") {
                    if let content = center.page(page.id) { goThere(content) }
                }
            }
        }
        .padding(Design.NowPlaying.inset)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Design.NowPlaying.radius))
    }

    @ViewBuilder private var picture: some View {
        let size = Design.NowPlaying.picture
        if let icon = center.page(page.id)?.favicon {
            Image(nsImage: icon).resizable().interpolation(.high).frame(width: size, height: size)
        } else {
            Image(systemName: page.hasVideo ? "play.rectangle.fill" : "music.note")
                .font(Design.Text.title)
                .frame(width: size, height: size)
        }
    }

    private func control(_ symbol: String, _ help: String, _ action: @escaping @MainActor () async -> Void) -> some View
    {
        Button {
            Runtime.live.task { @MainActor in await action() }
        } label: {
            Image(systemName: symbol)
                .font(Design.Text.secondary.weight(Design.Symbol.weight))
                .frame(width: Design.Size.glyphFrame, height: Design.Size.glyphFrame)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }
}
