import AemiTestKit
import AppKit
import Foundation
import Observation
import SunsetPrivate
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// A page's Now Playing card, read from the page by Sunset's own world (ADR-0115): its media session's title, artist and
/// artwork, whether it plays; and what a card does to it. The page makes its own sound (a WAV it writes), so nothing is
/// fetched. Previous and next go to a sender given here: a test never sends the system a real media command.
@MainActor @Suite("A page's Now Playing card", .serialized, .timeLimit(.minutes(1)))
final class NowPlayingPageTests {
    private var windows: [NSWindow] = []

    deinit {
        MainActor.assumeIsolated { windows.forEach { $0.close() } }
    }

    static let host = "media.example"
    static let page = """
        <audio id="a" loop></audio>
        <script>
        const rate = 8000, n = rate * 30, b = new ArrayBuffer(44 + n * 2), v = new DataView(b);
        const s = (o, t) => { for (let i = 0; i < t.length; i++) v.setUint8(o + i, t.charCodeAt(i)); };
        s(0, 'RIFF'); v.setUint32(4, 36 + n * 2, true); s(8, 'WAVE'); s(12, 'fmt '); v.setUint32(16, 16, true);
        v.setUint16(20, 1, true); v.setUint16(22, 1, true); v.setUint32(24, rate, true); v.setUint32(28, rate * 2, true);
        v.setUint16(32, 2, true); v.setUint16(34, 16, true); s(36, 'data'); v.setUint32(40, n * 2, true);
        for (let i = 0; i < n; i++) v.setInt16(44 + i * 2, Math.sin(i * 2 * Math.PI * 440 / rate) * 300, true);
        document.getElementById('a').src = URL.createObjectURL(new Blob([b], {type: 'audio/wav'}));
        navigator.mediaSession.metadata = new MediaMetadata({title: 'Song', artist: 'Band',
            artwork: [{src: 'https://media.example/small.png', sizes: '64x64'}, {src: 'https://media.example/art.png', sizes: '512x512'}]});
        window.actions = [];
        for (const a of ['nexttrack', 'previoustrack']) navigator.mediaSession.setActionHandler(a, () => window.actions.push(a));
        </script>
        """

    private func playing() async throws -> (WebContent, NowPlaying) {
        let settings = WebSettings(applicationName: "x")
        let page = WebContent(url: URL(string: "https://\(Self.host)/"), settings: settings)
        page.permissions.set(.allow, .autoplay, for: Self.host)
        let center = NowPlaying()
        page.nowPlaying = center
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        // Media plays in a view that is in a window, as a page in a pane is.
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        windows.append(window)
        view.loadHTMLString(Self.page, baseURL: URL(string: "https://\(Self.host)/"))
        await until { !page.isLoading && page.webView?.url?.host() == Self.host }
        _ = try await view.callAsyncJavaScript("await document.getElementById('a').play()", contentWorld: .page)
        await until { center.stack.front?.isPlaying == true }
        return (page, center)
    }

    @Test func `a page that plays has a card: its session's title, artist and largest artwork, its host`() async throws
    {
        let (page, center) = try await playing()
        let card = try #require(center.stack.front)
        #expect(card.id == page.mediaID)
        #expect(card.title == "Song" && card.artist == "Band" && card.host == Self.host)
        #expect(card.artwork == URL(string: "https://media.example/art.png") && !card.hasVideo)
        page.stop()
        #expect(center.stack.pages.isEmpty, "the page went: its card went")
    }

    @Test func `a card pauses and plays its page, and mutes it`() async throws {
        let (page, center) = try await playing()
        let view = try #require(page.webView)
        await center.togglePlaying(page.mediaID)
        await until { center.stack.front?.isPlaying == false }
        let paused = try await view.callAsyncJavaScript(
            "return document.getElementById('a').paused",
            contentWorld: .page
        )
        #expect(paused as? Bool == true)
        #expect(center.stack.pages.count == 1, "paused, it keeps its card")
        await center.togglePlaying(page.mediaID)
        await until { center.stack.front?.isPlaying == true }
        center.toggleMuted(page.mediaID)
        #expect(page.isMuted && center.stack.front?.isMuted == true)
        page.stop()
    }

    /// n131: the card's back and forward buttons move 10 seconds in the media (they held playback instead); offered when
    /// the media has a length.
    @Test func `back and forward move 10 seconds in its media`() async throws {
        let (page, center) = try await playing()
        defer { page.stop() }
        let view = try #require(page.webView)
        #expect(center.stack.front?.canSeek == true)
        func now() async throws -> Double {
            try await view.callAsyncJavaScript("return document.getElementById('a').currentTime", contentWorld: .page)
                as? Double ?? -1
        }
        let start = try await now()
        await center.seek(page.mediaID, forward: true)
        let later = try await now()
        #expect(later >= start + 9.5, "\(start) to \(later)")
        await center.seek(page.mediaID, forward: false)
        #expect(try await now() < later - 9.5)
    }

    /// n131: played to its end, its card goes; dismissed, it goes too.
    @Test func `played to its end, its card goes`() async throws {
        let (page, center) = try await playing()
        defer { page.stop() }
        let view = try #require(page.webView)
        _ = try await view.callAsyncJavaScript(
            "const a = document.getElementById('a'); a.loop = false; a.currentTime = a.duration - 0.2;",
            contentWorld: .page
        )
        #expect(await RealWait.until(within: .seconds(10)) { center.stack.pages.isEmpty })
    }

    /// Muted from its tab or from its card, the page and its card say the same at once (n123).
    @Test func `muted from the tab or from the card: both show it`() async throws {
        let (page, center) = try await playing()
        defer { page.stop() }
        let id = try #require(center.stack.front?.id)
        page.toggleMuted()
        #expect(page.isMuted && center.stack.front?.isMuted == true, "muted from its tab")
        center.toggleMuted(id)
        #expect(!page.isMuted && center.stack.front?.isMuted == false, "unmuted from its card")
    }
}
