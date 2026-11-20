import WebKit

/// Tells its page which link is under the pointer (roadmap 0029 step 6). A script in Sunset's own script world listens to the
/// pointer over links and posts their addresses; the page's own scripts cannot post to it, nor see it.
@MainActor
final class LinkHover: PageScriptHandler, WKScriptMessageHandler {
    private static let name = "sunsetLink"
    private static let script = """
        (() => {
          let last = "";
          const send = v => { if (v !== last) { last = v; webkit.messageHandlers.sunsetLink.postMessage(v); } };
          addEventListener("mouseover", e => {
            const a = e.target && e.target.closest ? e.target.closest("a[href]") : null;
            send(a ? a.href : "");
          }, true);
          addEventListener("mouseout", e => { if (!e.relatedTarget) send(""); }, true);
        })();
        """

    /// Gives the configuration a controller of its own with the script and its handler. Its own, also for a page WebKit makes for
    /// another: that one's configuration comes with its opener's controller, whose handler tells the opener.
    static func install(on configuration: WKWebViewConfiguration, for content: WebContent) {
        configuration.userContentController = WKUserContentController()
        PageBridge(name: name, script: script, injection: .atDocumentStart, mainFrameOnly: false, world: .defaultClient)
            .install(on: configuration, handler: LinkHover(page: content))
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        content?.linkHovered(message.body)
    }
}
