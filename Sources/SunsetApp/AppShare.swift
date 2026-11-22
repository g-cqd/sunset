import AppKit
import CoreImage
import SunsetAppCore
import SunsetConfig
import SunsetMarkdown
import SunsetPane
import SunsetRender
import SunsetRenderMac
import SunsetRuntime
import SunsetShell
import SunsetTerminal
import SunsetWeb
import WebKit

/// The app's side of sharing a tab: the open tabs of every Space, and a feed of each one's frames. A page not in a window
/// (its tab not shown) is drawn in a window off screen while it is shared, as the probe measured; a terminal sends its
/// renderer's last frame, a document is drawn again from its rows.
@MainActor enum AppShare {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
    static var runtime = Runtime.live

    static func start() {
        WebShare.sources = { asking in sources(except: asking) }
        WebShare.feed = { id in feed(id) }
        WebShare.preview = { id in await preview(id) }
        WebShare.pickSystem = { await pickSystem() }
        WebShare.otherProfiles = AppConfiguration.shared.configuration.web.shareOtherProfiles
        // Reload As: every profile, and a profile's page settings.
        WebProfiles.all = {
            AppSpaces.all.profiles.profiles.map(\.profile).map { ($0.isFirst ? nil : $0.id, $0.name) }
        }
        ProfileNames.mark = { saved in
            guard let profile = WebContent.savedProfile(saved) else { return nil }
            return WebProfiles.all().first { $0.id == profile.id }?.name ?? "Another profile"
        }
        WebProfiles.settings = { id, like in PaneContentKinds.pageSettings(profile: id, privacy: like.privacy) }
    }

    /// Every open tab of every kind, by Space: pages, terminals, documents, the asking page itself among its Space's,
    /// marked; not a private page.
    static func sources(except asking: WebContent) -> [ShareSource] {
        var askingID: UUID?
        let tabs = AppSpaces.all.spaces.flatMap { space in
            space.tabs.items.flatMap(\.panes)
                .compactMap { pane -> ShareOffer.Tab? in
                    guard let content = space.contents[pane] else { return nil }
                    if content === asking { askingID = pane }
                    let kind: ShareOffer.Tab.Kind
                    switch content {
                        // A page not made yet (never shown) is offered too: it is made when chosen.
                        case let page as WebContent: kind = .page(host: page.url?.host(), isPrivate: page.isPrivate)
                        case let terminal as TerminalModel: kind = .terminal(started: terminal.lastSurface != nil)
                        case is DocumentContent: kind = .document
                        default: return nil
                    }
                    return ShareOffer.Tab(
                        id: pane,
                        kind: kind,
                        title: shownTitle(content),
                        space: space.space.name,
                        profile: space.space.profile
                    )
                }
        }
        return ShareOffer.sources(tabs, asking: askingID)
    }

    /// A page with no title of its own in this run (never loaded) is named by the title its address was last seen with,
    /// not by its host.
    private static func shownTitle(_ content: any PaneContent) -> String {
        if let page = content as? WebContent, page.pageTitle.isEmpty, let url = page.url,
            let seen = AppHistory.shared?.title(of: url.absoluteString)
        {
            return seen
        }
        return content.title
    }

    private static let picker = ScreenPicker()

    /// macOS's picker, then what is picked captured; stopped with the share.
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
                // Its tab marked while shared, as a page's is.
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

    /// The widest preview, in points: the share panel's cards.
    static let previewWidth = 320.0

    /// A tab as it is now, small, for the share panel: a page as it is drawn (not loaded for it: a page never loaded
    /// has none), a terminal and a document drawn now.
    static func preview(_ id: UUID) async -> CGImage? {
        switch anyContent(id) {
            case let page as WebContent:
                guard let view = page.webView, view.window != nil else { return nil }
                return await snapshot(view, width: min(view.bounds.width, previewWidth))
            // Drawn now: a terminal not on screen has no recent frame (seen blank in the panel); its card shows where
            // its text is.
            case let terminal as TerminalModel:
                guard let frame = await otherFrame(id) else { return nil }
                let crop = TerminalPreviewCrop.rect(
                    frame: CGSize(width: frame.width, height: frame.height),
                    cellWidth: terminal.renderer?.cellMetrics.cellWidth,
                    padding: terminal.paddingPixels,
                    ratio: Design.Optical.sharePreviewRatio
                )
                // CGImage crops from the top left; the crop is Core Image's, from the bottom left.
                let top = CGRect(
                    x: crop.minX,
                    y: CGFloat(frame.height) - crop.maxY,
                    width: crop.width,
                    height: crop.height
                )
                return frame.cropping(to: top) ?? frame
            case is DocumentContent:
                return await otherFrame(id)
            default:
                return nil
        }
    }

    /// A terminal's last frame (its renderer's surface), a document drawn again from its rows.
    private static func otherFrame(_ id: UUID) async -> CGImage? {
        switch anyContent(id) {
            case let terminal as TerminalModel:
                // Drawn now, shown or not; a terminal that was never shown has no session or size yet: nothing.
                await terminal.drawFrame()
                return terminal.lastSurface.flatMap { image(of: $0, on: terminal.layerBackground) }
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
        // Points; the snapshot is in the screen's pixels: the width asked is halved on a Retina screen.
        let scale = view.window?.backingScaleFactor ?? 2
        return await snapshot(view, width: min(view.bounds.width, widestFrame) / scale)
    }

    /// A page as it is drawn now, `width` points wide.
    private static func snapshot(_ view: WKWebView, width: Double) async -> CGImage? {
        let snapshot = WKSnapshotConfiguration()
        snapshot.afterScreenUpdates = false
        snapshot.snapshotWidth = NSNumber(value: width)
        guard let image = try? await view.takeSnapshot(configuration: snapshot) else { return nil }
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }

    /// A terminal's frame as an image, on its background made opaque: the frame leaves the background to the window
    /// (its material shows through), and alone it was a few glyphs on nothing (seen in the share panel).
    private static func image(of surface: IOSurface, on background: CGColor) -> CGImage? {
        let frame = CIImage(ioSurface: surface)
        let opaque = background.copy(alpha: 1) ?? background
        let ground = CIImage(color: CIColor(cgColor: opaque)).cropped(to: frame.extent)
        return images.createCGImage(frame.composited(over: ground), from: frame.extent)
    }
}
