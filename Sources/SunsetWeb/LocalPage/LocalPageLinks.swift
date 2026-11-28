package import Foundation
package import WebKit

/// The links of a page document, followed by Sunset (`LocalPageView`): a click on one is caught in a world of Sunset's own
/// (the page's scripts cannot post to it) and handed over. A page drawn from its text (`loadHTMLString`) is not let go to
/// another file by WebKit, so its navigation alone would not say it.
@MainActor package final class LocalPageLinks: NSObject, WKScriptMessageHandler {
    private static let name = "sunsetLink"
    private static let world = WKContentWorld.world(name: "sunset-local-page")
    private static let script = """
        document.addEventListener('click', function (event) {
          if (event.defaultPrevented || event.button !== 0) return;
          var link = event.target.closest && event.target.closest('a[href]');
          if (!link) return;
          var url = new URL(link.getAttribute('href'), document.baseURI);
          if (url.hash && url.href.split('#')[0] === document.baseURI.split('#')[0]) return;
          event.preventDefault();
          window.webkit.messageHandlers.\(name).postMessage(url.href);
        }, true);
        """

    private let follow: @MainActor (URL) -> Void

    private init(follow: @escaping @MainActor (URL) -> Void) {
        self.follow = follow
    }

    /// Catches the links of the pages `controller` shows; `follow` is given each one clicked.
    static func install(in controller: WKUserContentController, follow: @escaping @MainActor (URL) -> Void) {
        controller.addUserScript(
            WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: world)
        )
        controller.add(LocalPageLinks(follow: follow), contentWorld: world, name: name)
    }

    /// Lets go of the handler (the controller holds it).
    static func remove(from controller: WKUserContentController) {
        controller.removeScriptMessageHandler(forName: name, contentWorld: world)
    }

    package func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let text = message.body as? String, let url = URL(string: text) else { return }
        follow(url)
    }
}
