import WebKit

/// Tells its page which of its frames plays a video (n126: a site's player in a frame of its own, as Fox News's is, was
/// out of reach of picture in picture, which looked in the main frame only). A script in Sunset's own world, in every
/// frame, posts when a video there starts playing; the message says which frame. The page's scripts cannot post to it.
@MainActor
final class VideoFrameWatch: PageScriptHandler, WKScriptMessageHandler {
    private static let name = "sunsetVideoFrame"
    static let script = """
        addEventListener("play", (e) => {
          if (e.target instanceof HTMLVideoElement) webkit.messageHandlers.\(name).postMessage(1);
        }, true);
        """

    static func install(on configuration: WKWebViewConfiguration, for content: WebContent) {
        PageBridge.everyFrame(name, script).install(on: configuration, handler: VideoFrameWatch(page: content))
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        content?.videoFrame = message.frameInfo
    }
}
