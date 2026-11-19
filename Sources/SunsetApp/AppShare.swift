import AppKit
import CoreImage
import SunsetConfig
import SunsetMarkdown
import SunsetPane
import SunsetRuntime
import SunsetShell
import SunsetTerminal
import SunsetWeb
import WebKit

/// The app's side of sharing a tab (ADR-0082): the open tabs of every Space, and a feed of each one's frames. A page not in
/// a window (its tab not shown) is drawn in a window off screen while it is shared, as the probe measured; a terminal sends
/// its renderer's last frame, a document is drawn again from its rows.
@MainActor enum AppShare {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    static var runtime = Runtime.live

    static func start() {
        WebShare.sources = { asking in sources(except: asking) }
        WebShare.feed = { id in feed(id) }
        WebShare.pickSystem = { await pickSystem() }
        WebShare.otherProfiles = AppConfiguration.shared.configuration.web.shareOtherProfiles
        // Reload As (roadmap 0050 D): every profile, and a profile's page settings.
        WebProfiles.all = {
            AppSpaces.all.profiles.profiles.map(\.profile).map { ($0.isFirst ? nil : $0.id, $0.name) }
        }
        ProfileNames.mark = { saved in
            guard let profile = WebContent.savedProfile(saved) else { return nil }
            return WebProfiles.all().first { $0.id == profile.id }?.name ?? "Another profile"
        }
        WebProfiles.settings = { id, like in PaneContentKinds.pageSettings(profile: id, privacy: like.privacy) }
    }

    /// Every open tab of every kind, by Space (ADR-0082, step D): pages, terminals, documents, the asking page itself among its
    /// Space's, marked (the owner, 2026-11-19); not a private page.
    static func sources(except asking: WebContent) -> [ShareSource] {
        AppSpaces.all.spaces.flatMap { space in
            space.tabs.items.flatMap(\.panes)
                .compactMap { pane -> ShareSource? in
                    guard let content = space.contents[pane] else { return nil }
                    var host: String?
                    switch content {
                        // A page not made yet (never shown) is offered too: it is made when chosen.
                        case let page as WebContent:
                            guard !page.isPrivate else { return nil }
                            host = page.url?.host()
                        // A terminal never shown has no shell yet (it starts when first sized): nothing to send.
                        case let terminal as TerminalModel:
                            guard terminal.lastSurface != nil else { return nil }
                            host = nil
                        case is DocumentContent: host = nil
                        default: return nil
                    }
                    return ShareSource(
                        id: pane,
                        title: shownTitle(content),
                        space: space.space.name,
                        profile: space.space.profile,
                        host: host,
                        isAsking: content === asking
                    )
                }
        }
    }

    /// A page with no title of its own in this run (never loaded) is named by the title its address was last seen with,
    /// not by its host (roadmap 0057).
    private static func shownTitle(_ content: any PaneContent) -> String {
        if let page = content as? WebContent, page.pageTitle.isEmpty, let url = page.url,
            let seen = AppHistory.shared?.title(of: url.absoluteString)
        {
            return seen
        }
        return content.title
    }

    private static let picker = ScreenPicker()

    /// macOS's picker, then what is picked captured (ADR-0085); stopped with the share.
    static func pickSystem() async -> ShareFeed? {
        guard let filter = await picker.pick() else { return nil }
        let stream = ScreenStream()
        guard await stream.start(filter) else {
            ScreenPicker.done()
            return nil
        }
        return ShareFeed(
            frame: { await runtime.detached(priority: .userInitiated) { stream.nextImage() }.value },
            isOpen: { stream.isRunning },
            host: { nil },
            shared: { on in
                guard !on else { return }
                stream.stop()
                ScreenPicker.done()
            }
        )
    }

    private static func anyContent(_ id: UUID) -> (any PaneContent)? {
        for space in AppSpaces.all.spaces { if let content = space.contents[id] { return content } }
        return nil
    }

    private static func content(_ id: UUID) -> WebContent? {
        anyContent(id) as? WebContent
    }

    static func feed(_ id: UUID) -> ShareFeed? {
        switch anyContent(id) {
            case let other? where other is TerminalModel || other is DocumentContent:
                // Its tab marked while shared, as a page's is (roadmap 0057).
                return ShareFeed(
                    frame: { await otherFrame(id) },
                    isOpen: { anyContent(id) != nil },
                    host: { nil },
                    shared: { on in SharedPanes.shared.change(other, sharing: on) }
                )
            default: break
        }
        guard let page = content(id) else { return nil }
        page.makeLoadedForSharing()
        return ShareFeed(
            frame: { await frame(id) },
            isOpen: { content(id) != nil },
            host: { content(id)?.url?.host() },
            shared: { on in if let page = content(id) { SharedPanes.shared.change(page, sharing: on) } },
            page: { content(id) }
        )
    }

    /// A terminal's last frame (its renderer's surface), a document drawn again from its rows.
    private static func otherFrame(_ id: UUID) async -> CGImage? {
        switch anyContent(id) {
            case let terminal as TerminalModel:
                // Drawn now, shown or not; a terminal that was never shown has no session or size yet: nothing.
                await terminal.drawFrame()
                guard let surface = terminal.lastSurface else { return nil }
                return images.createCGImage(CIImage(ioSurface: surface), from: CIImage(ioSurface: surface).extent)
            case let document as DocumentContent:
                document.takePicture()
                return document.picture
            default: return nil
        }
    }

    private static let images = CIContext()

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
