import Foundation
import WebKit

/// Sharing a tab into this page: the sheet's question, and the session once a tab is chosen.
extension WebContent {
    /// Asks the sheet; one question at a time.
    /// The person is asked what to share, the asking frame named when it is not the page's site; only right after the
    /// person clicked or typed in the page (audit HIGH-05: the page's word that it was clicked is not taken).
    func askShare(frameHost: String?) async -> ShareChoice {
        guard shareRequest == nil, share == nil, hasRecentUserInput else { return .cancel }
        let offered = TabShare.offered(
            WebShare.sources(self),
            to: settings.profile,
            otherProfiles: WebShare.otherProfiles
        )
        return await withCheckedContinuation { continuation in
            let other = frameHost.flatMap { $0 == url?.host() ? nil : $0 }
            shareRequest = ShareRequest(sources: offered, frameHost: other) { [weak self] choice in
                self?.shareRequest = nil
                continuation.resume(returning: choice)
            }
        }
    }

    func startShare(from id: UUID, asker: String?) {
        guard let feed = WebShare.feed(id) else { return }
        startShare(feed, source: id, asker: asker)
    }

    /// Shares `feed` into this page: a tab's, or what was picked in macOS's picker (a source of its own then).
    /// `asker` is the origin of the frame that asked, the only one given its frames.
    func startShare(_ feed: ShareFeed, source: UUID, asker: String?) {
        guard shareWrapper != nil else { return }
        share?.stop(.stopped)
        let session = ShareSession(source: source, feed: feed, page: self, asker: asker)
        share = session
        capture = .screen
        session.start()
    }

    /// A page chosen to be shared that was never shown: made and loaded now, drawn off screen.
    package func makeLoadedForSharing() {
        if webView == nil { makeWebView(configuration: nil) }
        isUnloaded = false
    }

    /// The person stops every share of this page into a call, from its own tab (its site panel).
    package func stopBeingShared() {
        for session in WebShare.sessions where session.shares(self) { session.stop(.stopped) }
    }
}
