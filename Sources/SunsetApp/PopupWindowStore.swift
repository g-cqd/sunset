import AppKit
import SunsetRuntime
import SunsetShell
import SunsetWeb

/// The pop-up windows (task t132, the owner's design of 2026-11-20): a page a page opened as a pop-up, alone in a window of
/// its own with no sidebar, in no Space's tabs until it is moved to one. It outlives its opener; it is not kept by the session.
@MainActor final class PopupWindowStore {
    static let shared = PopupWindowStore()

    /// One pop-up: its page, the Space its opener was in (nil: a private window, or a window with a Space of its own), its window.
    final class Popup {
        let page: WebContent
        let openerSpace: UUID?
        weak var window: NSWindow?
        /// Moved to a Space as a tab: its window closes without stopping the page.
        var moved = false

        init(page: WebContent, openerSpace: UUID?) {
            self.page = page
            self.openerSpace = openerSpace
        }
    }

    private(set) var popups: [UUID: Popup] = [:]
    /// Where its tasks run (ADR-0087).
    var runtime = Runtime.live
    /// Opens the window of the pop-up with this id (SwiftUI's `openWindow`, given by the first window).
    var openWindow: (UUID) -> Void = { _ in }

    /// Gives `page` a pop-up window.
    func open(_ page: WebContent, openerSpace: UUID?) {
        let id = UUID()
        popups[id] = Popup(page: page, openerSpace: openerSpace)
        // The page closes itself (`window.close()`): its window goes.
        page.onExit = { [weak self] in self?.popups[id]?.window?.close() }
        openWindow(id)
    }

    func popup(_ id: UUID) -> Popup? {
        popups[id]
    }

    /// Its window is in place: sized as the page asked, centred on the window that acts.
    func attach(_ id: UUID, window: NSWindow) {
        guard let popup = popups[id], popup.window !== window else { return }
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
        let target = space.flatMap { AppSpaces.all.space($0) }
        let windows = TabRegistry.shared.allWindows()
        let showing = target.flatMap { target in windows.first { $0.tabs.space === target } }
        let acting = TabRegistry.shared.actingWindow.flatMap { window in
            TabRegistry.shared.tabs(for: window).map { (window: window, tabs: $0) }
        }
        popup.moved = true
        popup.page.onExit = {}
        if let (window, tabs) = showing ?? acting ?? windows.first {
            if let target, tabs.space !== target { tabs.show(space: target, in: AppSpaces.all) }
            WebOpening.wire(popup.page, in: tabs)
            tabs.adopt(popup.page)
            window.makeKeyAndOrderFront(nil)
        } else {
            AppActions.shared.handoff.append(popup.page)
            AppActions.shared.openTerminalWindow()
        }
        popup.window?.close()
    }
}
