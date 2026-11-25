import AppKit
import SunsetPane
import SunsetRuntime
import SunsetShell
import SunsetWeb
import SunsetWebModel

/// The pop-up windows: a page a page opened as a pop-up, alone in a window of its own with no sidebar, in no Space's tabs until
/// it is moved to one. It outlives its opener; it is not kept by the session.
@MainActor final class PopupWindowStore {
    static let shared = PopupWindowStore()

    /// One pop-up: its page, the Space its opener was in (nil: a private window, or a window with a Space of its own), its window.
    final class Popup {
        let page: WebContent
        let openerSpace: UUID?
        /// A page's pop-up, or a peek at a link from another app (back, forward, an address field).
        let kind: DetachedWindowKind
        weak var window: NSWindow?
        /// Moved to a Space as a tab: its window closes without stopping the page.
        var moved = false

        init(page: WebContent, openerSpace: UUID?, kind: DetachedWindowKind) {
            self.page = page
            self.openerSpace = openerSpace
            self.kind = kind
        }
    }

    private(set) var popups: [UUID: Popup] = [:]
    /// Where its tasks run.
    var runtime = Runtime.live
    /// Opens the window of the pop-up with this id (SwiftUI's `openWindow`, given by the first window).
    var openWindow: (UUID) -> Void = { _ in }

    /// Gives `page` a pop-up window.
    func open(_ page: WebContent, openerSpace: UUID?, kind: DetachedWindowKind = .popup) {
        let id = UUID()
        if kind == .peek, page.popupSize == nil { page.popupSize = PopupWindowLayout.peekPage }
        popups[id] = Popup(page: page, openerSpace: openerSpace, kind: kind)
        // The page closes itself (`window.close()`): its window goes.
        page.onExit = { [weak self] in self?.popups[id]?.window?.close() }
        // What it opens in turn: a pop-up as a pop-up, anything else in a peek of its own (it has no tabs to go to).
        page.onOpen = { [weak self] opened, placement in
            self?.open(opened, openerSpace: openerSpace, kind: placement == .popup ? .popup : .peek)
        }
        openWindow(id)
    }

    func popup(_ id: UUID) -> Popup? {
        popups[id]
    }

    /// Its window is in place: sized as the page asked, centred on the window that acts.
    func attach(_ id: UUID, window: NSWindow) {
        guard let popup = popups[id], popup.window !== window else { return }
        // Each pop-up its own size: SwiftUI's saved frame for the scene came back over it (seen 2026-11-20).
        window.setFrameAutosaveName("")
        window.isRestorable = false
        popup.window = window
        let parent = TabRegistry.shared.actingWindow
        // A turn later: SwiftUI sizes a new window to its scene's default once it is attached (seen 2026-11-20: 520 by 640
        // whatever was set here).
        runtime.task { @MainActor [weak window] in
            await self.runtime.yieldTurn()
            guard let window else { return }
            if let size = popup.page.popupSize {
                window.setContentSize(
                    PopupWindowLayout(AppConfiguration.shared.configuration).windowSize(forPage: size)
                )
            }
            if let frame = parent?.frame {
                window.setFrameOrigin(
                    NSPoint(x: frame.midX - window.frame.width / 2, y: frame.midY - window.frame.height / 2)
                )
            }
            if popup.kind == .peek {
                if AppConfiguration.shared.focusesOpenedTabOrPeek {
                    window.makeKeyAndOrderFront(nil)
                } else if let parent, parent.isVisible {
                    window.order(.below, relativeTo: parent.windowNumber)
                    parent.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    /// Its window closed: the page stops, unless it was moved to a Space.
    func closed(_ id: UUID) {
        guard let popup = popups.removeValue(forKey: id) else { return }
        if !popup.moved { popup.page.stop() }
    }

    /// The page becomes a tab of `space` (nil: of the window that acts), in a window showing it, which comes forward; the pop-up
    /// window closes. The page keeps its own website data (its opener's, which a sign-in needs).
    func move(_ id: UUID, to space: UUID?) {
        guard let popup = popups[id] else { return }
        let isPrivate = popup.page.isPrivate
        // A private page to a private window only, a normal page to a normal one (seen 2026-11-20: a private page's went to a
        // Space).
        let fitting = TabRegistry.shared.allWindows()
            .filter {
                DetachedWindowKind.fits(window: .init(isPrivate: $0.tabs.isPrivateWindow), private: isPrivate)
            }
        let target = isPrivate ? nil : space.flatMap { AppSpaces.all.space($0) }
        let showing = target.flatMap { target in fitting.first { $0.tabs.space === target } }
        let acting = TabRegistry.shared.actingWindow.flatMap { window in fitting.first { $0.window === window } }
        popup.moved = true
        popup.page.onExit = {}
        if let (window, tabs) = showing ?? acting ?? fitting.first {
            if let target, tabs.space !== target { tabs.show(space: target, in: AppSpaces.all) }
            let destinationProfile = PaneContentKinds.profile(of: tabs)
            // If moving a non-private popup into a Space of a different profile, reload it under that profile so its
            // session/cookies never leak into the destination Space.
            if !isPrivate, popup.page.settings.profile != destinationProfile {
                let descriptor = PaneDescriptor(
                    kind: WebContent.kind,
                    state: popup.page.url.map { ["url": $0.absoluteString] } ?? [:]
                )
                popup.page.stop()
                tabs.newTab(descriptor)
            } else {
                WebOpening.wire(popup.page, in: tabs)
                tabs.adopt(popup.page)
            }
            window.makeKeyAndOrderFront(nil)
        } else if isPrivate {
            AppActions.shared.handoff.append(popup.page)
            AppActions.shared.newPrivateWindow()
        } else {
            AppActions.shared.handoff.append(popup.page)
            AppActions.shared.openTerminalWindow()
        }
        popup.window?.close()
    }
}
