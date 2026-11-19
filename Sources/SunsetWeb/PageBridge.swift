import WebKit

/// A page's script and the handler of what it posts (roadmap 0086 E: five bridges each installed themselves the same way):
/// the script added to the configuration's controller, the handler under its name, both in one world.
struct PageBridge {
    let name: String
    let script: String
    let injection: WKUserScriptInjectionTime
    let mainFrameOnly: Bool
    let world: WKContentWorld

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
}
