import AppKit
import SunsetConfig
import SunsetPane
import SunsetShell
import SunsetWeb
import WebKit

/// The app's side of sharing a tab (ADR-0082): the open tabs of every Space, and a feed of a web tab's frames. A page not in
/// a window (its tab not shown) is drawn in a window off screen while it is shared, as the probe measured.
@MainActor enum AppShare {
    static func start() {
        WebShare.sources = { asking in sources(except: asking) }
        WebShare.feed = { id in feed(id) }
        WebShare.otherProfiles = AppConfiguration.shared.configuration.web.shareOtherProfiles
    }

    /// Every open tab that can be drawn now, by Space; not the asking page itself.
    static func sources(except asking: WebContent) -> [ShareSource] {
        AppSpaces.all.spaces.flatMap { space in
            space.tabs.items.flatMap(\.panes)
                .compactMap { pane -> ShareSource? in
                    // A page not made yet (never shown) is offered too: it is made when chosen.
                    guard let page = space.contents[pane] as? WebContent, page !== asking, !page.isPrivate else {
                        return nil
                    }
                    return ShareSource(
                        id: pane,
                        title: page.title,
                        space: space.space.name,
                        profile: space.space.profile,
                        host: page.url?.host()
                    )
                }
        }
    }

    private static func content(_ id: UUID) -> WebContent? {
        for space in AppSpaces.all.spaces { if let page = space.contents[id] as? WebContent { return page } }
        return nil
    }

    static func feed(_ id: UUID) -> ShareFeed? {
        guard let page = content(id) else { return nil }
        page.makeLoadedForSharing()
        return ShareFeed(
            frame: { await frame(id) },
            isOpen: { content(id) != nil },
            host: { content(id)?.url?.host() },
            shared: { on in if let page = content(id) { page.sharedInto = max(0, page.sharedInto + (on ? 1 : -1)) } }
        )
    }

    /// The widest frame sent, in points: 1920 (a 1080p call); a Retina snapshot would be twice the pixels for nothing.
    static let widestFrame = 1920.0

    private static func frame(_ id: UUID) async -> CGImage? {
        guard let view = content(id)?.webView else { return nil }
        if view.window == nil { OffscreenHost.shared.hold(view) }
        let snapshot = WKSnapshotConfiguration()
        snapshot.afterScreenUpdates = false
        // Points; the snapshot is in the screen's pixels: the width asked is halved on a Retina screen.
        let scale = view.window?.backingScaleFactor ?? 2
        snapshot.snapshotWidth = NSNumber(value: min(view.bounds.width, widestFrame) / scale)
        guard let image = try? await view.takeSnapshot(configuration: snapshot) else { return nil }
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}
