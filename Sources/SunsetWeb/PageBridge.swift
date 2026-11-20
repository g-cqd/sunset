import WebKit

/// A page's script and the handler of what it posts (roadmap 0086 E: five bridges each installed themselves the same way):
/// the script added to the configuration's controller, the handler under its name, both in one world.
struct PageBridge {
    let name: String
    let script: String
    let injection: WKUserScriptInjectionTime
    let mainFrameOnly: Bool
    let world: WKContentWorld

    /// A watch of the page in Sunset's own script world, in the page itself (not its frames): what the page watchers are.
    static func ownWorld(_ name: String, _ script: String, at injection: WKUserScriptInjectionTime) -> Self {
        Self(name: name, script: script, injection: injection, mainFrameOnly: true, world: .defaultClient)
    }

    /// Adds the script and `handler`, which posts without a reply.
    func install(on configuration: WKWebViewConfiguration, handler: some WKScriptMessageHandler) {
        addScript(to: configuration)
        configuration.userContentController.add(handler, contentWorld: world, name: name)
    }

    /// Adds the script and `handler`, which answers what is posted.
    func install(on configuration: WKWebViewConfiguration, replying handler: some WKScriptMessageHandlerWithReply) {
        addScript(to: configuration)
        configuration.userContentController.addScriptMessageHandler(handler, contentWorld: world, name: name)
    }

    private func addScript(to configuration: WKWebViewConfiguration) {
        configuration.userContentController.addUserScript(
            WKUserScript(source: script, injectionTime: injection, forMainFrameOnly: mainFrameOnly, in: world)
        )
    }

    /// A script's end that watches the page for `function`, once the document is there: `function` run first when `first`, then
    /// at each change under `root` (the three page watchers each wrote this; roadmap 0086 E).
    static func watching(_ function: String, root: String, options: String, first: Bool) -> String {
        """
          const start = () => {
            \(first ? function + "();" : "")
            new MutationObserver(\(function)).observe(\(root), \(options));
          };
          if (document.readyState === "loading") addEventListener("DOMContentLoaded", start); else start();
        """
    }
}
