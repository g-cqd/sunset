import WebKit

/// Puts a site on the kept list when a password is sent from one of its pages (ADR-0081, 2): a script in Sunset's own world,
/// in every frame, watches for a form sent, or Enter or a click on a button, while a password field of the page holds
/// something, and posts once a page; the page's own scripts cannot post to it. Not in a private window.
@MainActor
final class SignInWatch: NSObject, WKScriptMessageHandler {
    private static let name = "sunsetSignIn"
    static let script = """
        (() => {
          let sent = false;
          const filled = (root) => [...(root || document).querySelectorAll('input[type=password]')].some(f => f.value.length > 0);
          const post = (root) => {
            if (sent || !filled(root)) return;
            sent = true;
            webkit.messageHandlers.\(name).postMessage(1);
          };
          addEventListener('submit', (e) => post(e.target), true);
          addEventListener('keydown', (e) => { if (e.key === 'Enter' && e.target && e.target.form !== undefined) post(e.target.form || document); }, true);
          addEventListener('click', (e) => {
            const button = e.target && e.target.closest && e.target.closest('button, input[type=submit], [role=button]');
            if (button) post(button.form || document);
          }, true);
        })();
        """

    /// The page's profile: the site is kept for it (roadmap 0050 E).
    private let profile: UUID?

    private init(profile: UUID?) { self.profile = profile }

    /// Adds the script and its handler to the configuration's controller, unless the page is private.
    static func install(on configuration: WKWebViewConfiguration, privately: Bool, profile: UUID?) {
        guard !privately else { return }
        let controller = configuration.userContentController
        controller.addUserScript(
            WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false, in: .defaultClient)
        )
        controller.add(SignInWatch(profile: profile), contentWorld: .defaultClient, name: name)
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        let host = message.frameInfo.securityOrigin.host
        guard !host.isEmpty else { return }
        KeptSites.shared.set(true, for: host, profile: profile)
    }
}
