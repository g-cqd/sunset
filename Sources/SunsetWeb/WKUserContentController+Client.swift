import WebKit

extension WKUserContentController {
    /// `source` at each frame's document end, in Sunset's own world, and `handler` there under `name`: what a page's own
    /// scripts cannot see, call or post to.
    func addClientScript(_ source: String, handler: any WKScriptMessageHandler, name: String) {
        addUserScript(
            WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false, in: .defaultClient)
        )
        add(handler, contentWorld: .defaultClient, name: name)
    }
}
