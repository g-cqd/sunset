import Foundation
import SunsetPrivate
import WebKit

/// Force reload: for a page stuck loading, or whose process hangs or crashed. Its process is ended and the page loads
/// again in a new one, where it was, its history kept (probed: `/tmp/killprobe`).
extension WebContent {
    package func forceReload() {
        failure = nil
        guard let view = webView else {
            if url != nil {
                makeWebView(configuration: nil)
                isUnloaded = false
            }
            return
        }
        let history = view.interactionState
        let address = view.url ?? url
        view.stopLoading()
        forcing = true
        let ended = WebProcessControl.end(view)
        forcing = false
        failure = nil
        if ended, let history {
            view.interactionState = history
        } else if let address {
            view.load(URLRequest(url: address, cachePolicy: .reloadIgnoringLocalCacheData))
        }
    }
}
