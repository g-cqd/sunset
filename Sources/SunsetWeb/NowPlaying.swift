import Foundation
package import Observation
internal import SunsetPrivate
import SunsetRuntime
package import SunsetWebModel

/// What plays in Sunset's pages, for the Now Playing cards (roadmap 0114, ADR-0115): each page reports itself when it
/// starts or stops playing, changes its title, or goes; a card's actions go back to its page.
@MainActor @Observable
package final class NowPlaying {
    package static let shared = NowPlaying()

    package private(set) var stack = MediaStack()
    @ObservationIgnored private var pages: [MediaPage.ID: Weak] = [:]
    /// Shows a page's tab, in its Space and window (the app's): a card's Go There, and picture in picture's way back.
    @ObservationIgnored package var goThere: @MainActor (WebContent) -> Void = { _ in }

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
        // Played to its end: its card goes (n131).
        if media.ended, !media.playing, !page.playsSound {
            stack.remove(page.mediaID)
            return
        }
        let host = page.url?.host() ?? ""
        var card = MediaPage(
            id: page.mediaID,
            title: media.title.isEmpty ? page.pageTitle : media.title,
            artist: media.artist.isEmpty ? nil : media.artist,
            host: host,
            artwork: media.artwork,
            hasVideo: media.video,
            isPlaying: media.playing || page.playsSound,
            isMuted: page.isMuted
        )
        card.canSeek = media.seekable
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
        page(id)?.toggleMuted()
    }

    /// The page was muted or unmuted (from its tab, its menu, its card): its card follows.
    func mutedChanged(_ page: WebContent) {
        guard var card = stack.pages.first(where: { $0.id == page.mediaID }), card.isMuted != page.isMuted else {
            return
        }
        card.isMuted = page.isMuted
        stack.update(card)
    }

    /// Brings the card `cards` further back to the front.
    package func scroll(_ cards: Int) {
        stack.scroll(cards)
    }

    /// The card's video in the system's picture in picture window (ADR-0115): WebKit's own toggle when it offers one, else
    /// the video's presentation mode set from Sunset's world.
    package func pictureInPicture(_ id: MediaPage.ID) {
        guard let page = page(id), let view = page.webView else { return }
        if WebNowPlaying.togglePictureInPicture(view) { return }
        // In the frame that plays a video when one does (a player in a frame of its own), else the page.
        let frame = page.videoFrame
        runtimeTask { await MediaReading.pictureInPicture(view, in: frame) }
    }

    private func runtimeTask(_ work: @escaping @MainActor () async -> Void) {
        Runtime.live.task { @MainActor in await work() }
    }

    /// 10 seconds on or back in the card's media (n131: next and previous held playback instead of seeking).
    package func seek(_ id: MediaPage.ID, forward: Bool) async {
        guard let page = page(id), let view = page.webView else { return }
        await MediaReading.seek(view, by: forward ? 10 : -10, in: page.videoFrame)
    }

    /// The person dismissed the card: it goes, and stays gone while its page plays on (n131).
    package func dismiss(_ id: MediaPage.ID) {
        stack.dismiss(id)
    }
}
