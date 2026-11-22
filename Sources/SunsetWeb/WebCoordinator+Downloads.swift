import SunsetPrivate
import SunsetRuntime
import SunsetWebModel
import WebKit

/// What becomes a download: an attachment, and what WebKit cannot show; what it can show (a PDF, a picture) opens in the page.
extension WebCoordinator {
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse) async
        -> WKNavigationResponsePolicy
    {
        guard response.isForMainFrame else { return .allow }
        // An extension's package (a store's "Download file", a link to a `.crx`): installed after its prompt, not downloaded.
        // A private page's go to Downloads.
        if let address = response.response.url, let content, !content.isPrivate,
            ExtensionPackage.isPackage(mime: response.response.mimeType, path: address.path())
        {
            ExtensionHosts.shared.installPackage(address, content.settings.profile)
            return .cancel
        }
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
    /// method (nothing took it, and nothing happened).
    static func installMenuDownloads() {
        WebDownloadHooks.install(
            on: WebCoordinator.self,
            contextMenuDownload: { delegate, webView, download in
                guard let coordinator = delegate as? WebCoordinator, let webView = webView as? WKWebView,
                    let download = download as? WKDownload
                else { return }
                coordinator.adopt(download, from: webView)
            },
            saveData: { delegate, webView, file in
                guard let coordinator = delegate as? WebCoordinator, let webView = webView as? WKWebView else { return }
                coordinator.save(file, in: webView)
            }
        )
    }

    /// Download Video's bytes, saved as the page's downloads are.
    func save(_ file: WebDownloadHooks.SavedBytes, in webView: WKWebView) {
        let content = content
        let saved = DownloadCenter.Saved(
            data: file.data,
            name: file.name,
            source: file.source,
            origin: webView.url,
            isPrivate: content?.isPrivate ?? false
        )
        content?.runtime
            .task { @MainActor in
                _ = await DownloadCenter.shared.save(
                    saved,
                    folder: content?.settings.downloadFolder,
                    asks: content?.settings.askWhereToSave
                )
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
