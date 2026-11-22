import WebKit

/// Tells its page that the page's text changed while its title did not: a script in Sunset's own script world watches
/// the document's body and posts once at most every two seconds; the page's own scripts cannot post to it.
@MainActor
final class TextWatch: PageScriptHandler, WKScriptMessageHandler {
    private static let name = "sunsetText"
    /// The least time between two posts, in milliseconds.
    static let interval = 2000
    static let script = """
        (() => {
          let pending = null, last = 0;
          const post = () => { pending = null; last = Date.now(); webkit.messageHandlers.\(name).postMessage(1); };
          const changed = () => {
            if (pending !== null) return;
            pending = setTimeout(post, Math.max(0, \(interval) - (Date.now() - last)));
          };
        \(PageBridge.watching(
            "changed",
            root: "document.body || document.documentElement",
            options: "{ subtree: true, childList: true, characterData: true }",
            first: false
        ))
        })();
        """

    /// Adds the script and its handler to the configuration's controller.
    static func install(on configuration: WKWebViewConfiguration, for content: WebContent) {
        PageBridge.ownWorld(name, script, at: .atDocumentEnd)
            .install(on: configuration, handler: TextWatch(page: content))
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame else { return }
        content?.textChanged(at: ProcessInfo.processInfo.systemUptime)
    }
}
