import AppKit
import SunsetRuntime
import SunsetShell
import SunsetWebModel
import SwiftUI

/// One Now Playing card (roadmap 0114), laid out as Control Center's: the site's icon, the title (scrolling when it is
/// long) and the artist or site, the way to its tab and the card's dismissal; under them mute at the leading edge, play or
/// pause in the middle between 10 seconds back and on (when the media can be moved in), picture in picture at the trailing
/// edge for a video. Only what the media takes is shown (n131).
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
                HStack(spacing: 0) {
                    control("arrow.up.forward.app", "Go to Its Tab") {
                        if let content = center.page(page.id) { center.goThere(content) }
                    }
                    control("xmark", "Dismiss") { center.dismiss(page.id) }
                }
            }
            // The middle centred whatever the edges hold.
            ZStack {
                HStack(spacing: Design.Space.s) {
                    if page.canSeek {
                        control("gobackward.10", "Back 10 Seconds") { await center.seek(page.id, forward: false) }
                    }
                    control(page.isPlaying ? "pause.fill" : "play.fill", page.isPlaying ? "Pause" : "Play") {
                        await center.togglePlaying(page.id)
                    }
                    .scaleEffect(Design.NowPlaying.mainControl)
                    if page.canSeek {
                        control("goforward.10", "Forward 10 Seconds") { await center.seek(page.id, forward: true) }
                    }
                }
                HStack(spacing: 0) {
                    control(
                        page.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                        page.isMuted ? "Unmute" : "Mute"
                    ) {
                        center.toggleMuted(page.id)
                    }
                    Spacer(minLength: 0)
                    if pictureInPicture, page.hasVideo {
                        control("pip.enter", "Picture in Picture") { center.pictureInPicture(page.id) }
                    }
                }
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
        .buttonStyle(.quietGlyph)
        .help(help)
        .accessibilityLabel(help)
    }
}
