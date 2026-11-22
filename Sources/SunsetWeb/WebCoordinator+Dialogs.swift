import WebKit

/// JavaScript's `alert`, `confirm` and `prompt`, as a panel in the page's pane.
extension WebCoordinator {
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async {
        _ = await content?.ask(.alert, message: message, host: frame.securityOrigin.host)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async -> Bool {
        guard case .ok = await content?.ask(.confirm, message: message, host: frame.securityOrigin.host) else {
            return false
        }
        return true
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo
    ) async -> String? {
        let kind = PageDialog.Kind.prompt(defaultText: defaultText ?? "")
        guard case .ok(let text) = await content?.ask(kind, message: prompt, host: frame.securityOrigin.host) else {
            return nil
        }
        return text ?? ""
    }
}
