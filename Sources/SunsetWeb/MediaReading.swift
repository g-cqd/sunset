import Foundation
import SunsetWebModel
import WebKit

/// What a page's media is, read by Sunset's own world (ADR-0115): its media session's title, artist and largest artwork,
/// whether a video or a sound of its main frame plays. Nothing is added to the page; it cannot see the reading.
@MainActor
enum MediaReading {
    static let script = """
        const media = [...document.querySelectorAll('video, audio')];
        const meta = navigator.mediaSession && navigator.mediaSession.metadata;
        const art = meta && meta.artwork && meta.artwork.length ? meta.artwork[meta.artwork.length - 1].src : '';
        const playing = media.filter(m => !m.paused && !m.ended);
        return {
            title: meta && meta.title || '', artist: meta && meta.artist || '', artwork: art || '',
            video: (playing.length ? playing : media).some(m => m.tagName === 'VIDEO' && m.videoWidth > 0),
            playing: playing.length > 0
        };
        """

    /// What a page's media is, as read.
    struct Media {
        var title: String
        var artist: String
        var artwork: URL?
        var video: Bool
        var playing: Bool
    }

    /// The media of the page in `view`: nil when it cannot be read (no page, a page that does not answer).
    static func read(_ view: WKWebView) async -> Media? {
        guard let answer = try? await view.callAsyncJavaScript(script, contentWorld: .defaultClient) as? [String: Any]
        else { return nil }
        return Media(
            title: answer["title"] as? String ?? "",
            artist: answer["artist"] as? String ?? "",
            artwork: (answer["artwork"] as? String).flatMap { $0.isEmpty ? nil : URL(string: $0) },
            video: answer["video"] as? Bool ?? false,
            playing: answer["playing"] as? Bool ?? false
        )
    }

    /// Pauses every media of the main frame, from Sunset's world.
    static func pause(_ view: WKWebView) async {
        _ = try? await view.callAsyncJavaScript(
            "document.querySelectorAll('video, audio').forEach(m => m.pause())",
            contentWorld: .defaultClient
        )
    }

    /// Plays again the media of the main frame that was paused last (the one furthest in), from Sunset's world.
    static func resume(_ view: WKWebView) async {
        _ = try? await view.callAsyncJavaScript(
            "const m = [...document.querySelectorAll('video, audio')].filter(m => m.paused && !m.ended).sort((a, b) => b.currentTime - a.currentTime)[0]; if (m) await m.play();",
            contentWorld: .defaultClient
        )
    }

    /// Puts the main frame's playing video, else its first, in picture in picture, from Sunset's world.
    static func pictureInPicture(_ view: WKWebView, in frame: WKFrameInfo? = nil) async {
        _ = try? await view.callAsyncJavaScript(pictureInPictureScript, in: frame, contentWorld: .defaultClient)
    }

    /// The video floating in picture in picture, back in its page.
    static func inline(_ view: WKWebView, in frame: WKFrameInfo? = nil) async {
        _ = try? await view.callAsyncJavaScript(
            "for (const v of document.querySelectorAll('video')) if (v.webkitPresentationMode === 'picture-in-picture') v.webkitSetPresentationMode('inline');",
            in: frame,
            contentWorld: .defaultClient
        )
    }

    /// The video playing (else the first) of a frame, into picture in picture when it can go there.
    static let pictureInPictureScript =
        "const all = [...document.querySelectorAll('video')]; const v = all.find(v => !v.paused) || all[0]; if (v && v.webkitSupportsPresentationMode && v.webkitSupportsPresentationMode('picture-in-picture')) v.webkitSetPresentationMode('picture-in-picture');"

    /// Pauses and plays again what plays in the main frame, from Sunset's world: the page becomes the system's now
    /// playing, so that a media command reaches it (diary 2026-11-22-06).
    static func replay(_ view: WKWebView) async {
        _ = try? await view.callAsyncJavaScript(
            "const m = [...document.querySelectorAll('video, audio')].find(m => !m.paused && !m.ended); if (m) { m.pause(); await m.play(); }",
            contentWorld: .defaultClient
        )
    }
}
