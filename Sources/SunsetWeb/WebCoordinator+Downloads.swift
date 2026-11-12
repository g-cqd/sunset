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
        DownloadCenter.shared.adopt(download, origin: webView.url, isPrivate: content?.isPrivate ?? false)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        DownloadCenter.shared.adopt(download, origin: webView.url, isPrivate: content?.isPrivate ?? false)
    }
}
