import WebKit

/// Tells its page that the page changed its icon (roadmap 0035 H): a script in Sunset's own script world watches the
/// document's `<link rel="icon">` elements and posts the new address; the page's own scripts cannot post to it.
@MainActor
final class IconWatch: NSObject, WKScriptMessageHandler {
    private static let name = "sunsetIcon"
    static let script = """
        (() => {
          let last = null;
          const look = () => {
            const l = document.querySelector('link[rel~="icon"], link[rel="apple-touch-icon"]');
            const href = l ? l.href : "";
            if (last === null) { last = href; return; }
            if (href && href !== last) { last = href; webkit.messageHandlers.\(name).postMessage(href); }
          };
          const start = () => {
            look();
            new MutationObserver(look).observe(document.head || document.documentElement,
              { subtree: true, childList: true, attributes: true, attributeFilter: ["href", "rel"] });
          };
          if (document.readyState === "loading") addEventListener("DOMContentLoaded", start); else start();
        })();
        """

    private weak var content: WebContent?

    private init(content: WebContent) {
        self.content = content
    }

    /// Adds the script and its handler to the configuration's controller (after `LinkHover` gave it its own).
    static func install(on configuration: WKWebViewConfiguration, for content: WebContent) {
        let controller = configuration.userContentController
        controller.addUserScript(
            WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true, in: .defaultClient)
        )
        controller.add(IconWatch(content: content), contentWorld: .defaultClient, name: name)
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, let address = message.body as? String else { return }
        content?.iconChanged(to: address)
    }
}
