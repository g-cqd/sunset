import Foundation
import SunsetPrivate
import WebKit

/// The one way a page's view ends: its tab closed (`stop`), its page unloaded to free memory, its page made again as another
/// profile (Reload As). Letting go of the view was not enough: whatever still held it (a host during its animation, the
/// off-screen window of a share) kept it playing (probed: `/tmp/closeprobe`).
extension WebContent {
    /// Ends the page's view now: its media suspended and paused, out of its window, its delegates gone, its page closed;
    /// `keepingHistory`, its place in its history kept to be made again.
    func endView(keepingHistory: Bool) {
        guard let view = webView else { return }
        if let tab = extensionTab {
            view.configuration.webExtensionController?.didCloseTab(tab, windowIsClosing: false)
            extensionTab = nil
        }
        if keepingHistory { savedHistory = view.interactionState as? Data }
        soundWatch = nil
        notificationClicks.end()
        observations = []
        view.stopLoading()
        view.setAllMediaPlaybackSuspended(true)
        view.pauseAllMediaPlayback()
        view.closeAllMediaPresentations {}
        view.navigationDelegate = nil
        view.uiDelegate = nil
        view.removeFromSuperview()
        WebProcessControl.close(view)
        webView = nil
        extensionPageHost = nil
        coordinator = nil
    }
}
