import AppKit
import WebKit

/// A page's file field, and a page whose process ended.
extension WebCoordinator {
    /// `<input type=file>`: the system's panel as a sheet on the page's window; nothing chosen, nothing given.
    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo
    ) async -> [URL]? {
        guard let window = webView.window else { return nil }
        let choice = FileChoice(multiple: parameters.allowsMultipleSelection, folders: parameters.allowsDirectories)
        let panel = choice.panel(host: frame.securityOrigin.host)
        return await panel.beginSheetModal(for: window) == .OK ? panel.urls : nil
    }

    /// The page's process ended (it crashed, or the system took its memory): our failure page, whose Try Again loads it again.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // Ended on purpose by a force reload, which loads it again at once.
        if content?.forcing == true { return }
        content?.failure = .processEnded(url: webView.url ?? content?.url)
    }
}
