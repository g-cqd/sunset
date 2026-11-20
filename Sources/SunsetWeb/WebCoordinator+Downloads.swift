import SunsetPrivate
import WebKit

/// What becomes a download (web step f): an attachment, and what WebKit cannot show; what it can show (a PDF, a picture) opens in the page.
extension WebCoordinator {
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse) async
        -> WKNavigationResponsePolicy
    {
        guard response.isForMainFrame else { return .allow }
        let disposition =
            (response.response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Disposition") ?? ""
        if disposition.lowercased().hasPrefix("attachment") || !response.canShowMIMEType { return .download }
        return .allow
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        adopt(download, from: webView)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        adopt(download, from: webView)
    }

    /// Download Image, Download Video and Download Linked File: WebKit makes the download itself and hands it over by a private
    /// method (the owner's note n64: nothing took it, and nothing happened).
    static func installMenuDownloads() {
        WebDownloadHooks.install(on: WebCoordinator.self) { delegate, webView, download in
            guard let coordinator = delegate as? WebCoordinator, let webView = webView as? WKWebView,
                let download = download as? WKDownload
            else { return }
            coordinator.adopt(download, from: webView)
        }
    }

    /// The download is the page's: in Sunset's list, in the page's folder, private with a private page.
    func adopt(_ download: WKDownload, from webView: WKWebView) {
        DownloadCenter.shared.adopt(
            download,
            origin: webView.url,
            isPrivate: content?.isPrivate ?? false,
            folder: content?.settings.downloadFolder,
            asks: content?.settings.askWhereToSave
        )
    }
}
