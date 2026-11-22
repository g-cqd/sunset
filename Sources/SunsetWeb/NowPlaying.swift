import Foundation
package import Observation
package import SunsetPrivate
import SunsetRuntime
package import SunsetWebModel

/// What plays in Sunset's pages, for the Now Playing cards (roadmap 0114, ADR-0115): each page reports itself when it
/// starts or stops playing, changes its title, or goes; a card's actions go back to its page.
@MainActor @Observable
package final class NowPlaying {
    package static let shared = NowPlaying()

    package private(set) var stack = MediaStack()
    /// Where previous and next go: the system's media commands, unless a test says otherwise.
    @ObservationIgnored package var sendCommand: @MainActor (WebNowPlaying.Command) -> Bool = { WebNowPlaying.send($0) }
    @ObservationIgnored private var pages: [MediaPage.ID: Weak] = [:]

    private struct Weak {
        weak var page: WebContent?
    }

    package init() {}

    /// The page whose card this is, while it is open.
    package func page(_ id: MediaPage.ID) -> WebContent? {
        pages[id]?.page
    }

    /// Reads `page` again and updates its card: a page that never played has none.
    func report(_ page: WebContent) async {
        guard let view = page.webView, let media = await MediaReading.read(view) else { return }
        let host = page.url?.host() ?? ""
        let card = MediaPage(
            id: page.mediaID,
            title: media.title.isEmpty ? page.pageTitle : media.title,
            artist: media.artist.isEmpty ? nil : media.artist,
            host: host,
            artwork: media.artwork,
            hasVideo: media.video,
            isPlaying: media.playing || page.playsSound,
            isMuted: page.isMuted
        )
        pages[page.mediaID] = Weak(page: page)
        stack.update(card)
    }

    /// The page went: its card goes.
    func gone(_ page: WebContent) {
        pages[page.mediaID] = nil
        stack.remove(page.mediaID)
    }

    /// Plays or pauses the card's page, through its own session.
    package func togglePlaying(_ id: MediaPage.ID) async {
        guard let page = page(id), let view = page.webView else { return }
        if stack.pages.first(where: { $0.id == id })?.isPlaying == true {
            // The page's own handler first; a page whose handler does not pause is paused by WebKit.
            await WebNowPlaying.pause(view)
            if await MediaReading.read(view)?.playing == true { await MediaReading.pause(view) }
        } else {
            await WebNowPlaying.play(view)
            if await MediaReading.read(view)?.playing != true { await MediaReading.resume(view) }
        }
        await report(page)
    }

    package func toggleMuted(_ id: MediaPage.ID) {
        guard let page = page(id) else { return }
        page.toggleMuted()
        if var card = stack.pages.first(where: { $0.id == id }) {
            card.isMuted = page.isMuted
            stack.update(card)
        }
    }

    /// Brings the card `cards` further back to the front.
    package func scroll(_ cards: Int) {
        stack.scroll(cards)
    }

    /// The card's video in the system's picture in picture window (ADR-0115): WebKit's own toggle when it offers one, else
    /// the video's presentation mode set from Sunset's world.
    package func pictureInPicture(_ id: MediaPage.ID) {
        guard let view = page(id)?.webView else { return }
        if WebNowPlaying.togglePictureInPicture(view) { return }
        runtimeTask { await MediaReading.pictureInPicture(view) }
    }

    private func runtimeTask(_ work: @escaping @MainActor () async -> Void) {
        Runtime.live.task { @MainActor in await work() }
    }

    /// Previous or next: the page is made the system's now playing again, then the command is sent (ADR-0115).
    package func skip(_ id: MediaPage.ID, forward: Bool) async {
        guard let page = page(id), let view = page.webView else { return }
        await MediaReading.replay(view)
        _ = sendCommand(forward ? .nextTrack : .previousTrack)
    }
}
