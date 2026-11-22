import AppKit
import SunsetRuntime
import SunsetShell
import SunsetWebModel
import SwiftUI

/// One Now Playing card (roadmap 0114), laid out as Control Center's: the site's icon, the title (scrolling when it is
/// long) and the artist or site, the way to its tab; under them mute, previous, play or pause, next, and picture in
/// picture for a video.
struct NowPlayingCard: View {
    let page: MediaPage
    let center: NowPlaying
    let pictureInPicture: Bool

    var body: some View {
        VStack(spacing: Design.Space.xs) {
            HStack(spacing: Design.Space.s) {
                picture
                VStack(alignment: .leading, spacing: Design.Space.hair) {
                    MarqueeText(page.title)
                    Text(page.artist ?? page.host).font(Design.Text.detail).foregroundStyle(.secondary).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                control("arrow.up.forward.app", "Go to Its Tab") {
                    if let content = center.page(page.id) { center.goThere(content) }
                }
            }
            HStack(spacing: 0) {
                control(page.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill", page.isMuted ? "Unmute" : "Mute") {
                    center.toggleMuted(page.id)
                }
                Spacer(minLength: 0)
                control("backward.fill", "Previous") { await center.skip(page.id, forward: false) }
                control(page.isPlaying ? "pause.fill" : "play.fill", page.isPlaying ? "Pause" : "Play") {
                    await center.togglePlaying(page.id)
                }
                .scaleEffect(Design.NowPlaying.mainControl)
                control("forward.fill", "Next") { await center.skip(page.id, forward: true) }
                Spacer(minLength: 0)
                // Its place is kept without a video, so that the controls stay centred.
                control("pip.enter", "Picture in Picture") { center.pictureInPicture(page.id) }
                    .opacity(pictureInPicture && page.hasVideo ? 1 : 0)
                    .disabled(!(pictureInPicture && page.hasVideo))
            }
        }
        .padding(Design.NowPlaying.inset)
        .contentTransition(.symbolEffect(.replace))
    }

    @ViewBuilder private var picture: some View {
        let size = Design.NowPlaying.picture
        if let icon = center.page(page.id)?.favicon {
            Image(nsImage: icon).resizable().interpolation(.high).frame(width: size, height: size)
        } else {
            Image(systemName: page.hasVideo ? "play.rectangle.fill" : "music.note")
                .font(Design.Text.body)
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
