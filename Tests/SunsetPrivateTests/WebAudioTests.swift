import SunsetPrivate
import Testing
import WebKit

@MainActor
struct WebAudioTests {
    @Test func `a page's sound can be watched and muted; a page that plays nothing is silent`() throws {
        let view = WKWebView()
        var seen: [Bool] = []
        let watch = try #require(WebAudio.watchPlaying(view) { seen.append($0) })
        #expect(!WebAudio.isPlaying(view) && seen.isEmpty)
        #expect(!WebAudio.isMuted(view))
        WebAudio.setMuted(true, on: view)
        #expect(WebAudio.isMuted(view))
        WebAudio.setMuted(false, on: view)
        #expect(!WebAudio.isMuted(view))
        _ = watch
    }
}
