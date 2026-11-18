import AppKit
import SunsetHost
import SunsetMarkdown
import SunsetPane
import SunsetShell
import SunsetTerminal
import SunsetWeb
import SwiftUI

/// A window starts: which Space it shows, and what it shows of it (ADR-0045, design 0004).
extension TerminalScene {
    func start() {
        AppActions.shared.openTerminalWindow = { openWindow(id: "terminal") }
        tabs.onEmpty = { dismiss() }
        tabs.wireContent = { wire($0) }
        AppDocuments.wire(tabs.shelf)
        tabs.onChange = { SessionStore.shared.scheduleSave() }
        SwitchProbe.startIfAsked(tabs)
        // Once for a window: its content can be built again while it stays (a change of decorations), with the same tabs.
        if !tabs.started {
            tabs.started = true
            if AppActions.shared.pendingPrivateWindow {
                // A Space of its own, never saved: its tabs go with it.
                tabs.makeContent = { makeContent($0) }
                startPrivate()
            } else if presentation.hostsTabsInWindow {
                startOnSpace()
            } else {
                startAsOneTab()
            }
        } else {
            tabs.makeContent = { makeContent($0) }
        }
        // Asked for with no window open: the settings (Cmd-,), the files Sunset was started with. Its only tabs, then.
        AppActions.shared.finishStarting(tabs)
    }

    /// A window that lists tabs is a view of one of the app's Spaces: its tabs are the Space's.
    private func startOnSpace() {
        let all = AppSpaces.all
        if AppActions.shared.handoff.isEmpty, let view = SessionStore.shared.takeView() {
            // A window of the session, or the one after the last was closed: the Space it showed, and what it had selected.
            tabs.show(space: all.space(view.space) ?? all.spaces[0], in: all)
            tabs.makeContent = { makeContent($0) }
            tabs.show(view)
            return
        }
        // A new window shows the Space of the window it was asked from (the one in front), else the first.
        let asked = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)?.space
        let space = asked.flatMap { all.contains($0) ? $0 : nil } ?? all.spaces[0]
        let others = space.viewerCount
        tabs.show(space: space, in: all)
        // The Space's tabs that have no content (read from the session, or stopped with its last window) get theirs.
        tabs.makeContent = { makeContent($0) }
        let nothingAsked = !AppActions.shared.pendingSettings && AppActions.shared.pendingFiles.isEmpty
        if !AppActions.shared.handoff.isEmpty {
            // Content that already runs (a page opened in a window of its own) is a tab of the Space, shown here.
            let content = AppActions.shared.handoff.removeFirst()
            wire(content)
            tabs.adopt(content)
        } else if space.tabs.isEmpty {
            if nothingAsked { tabs.newTab() }
        } else if others > 0 {
            // New Window: nothing selected, and the command bar open on a new tab (the owner, 2026-11-16).
            if nothingAsked { tabs.toggleBar() }
        } else if let first = space.lastShown ?? space.tabs.items.first?.id {
            tabs.select(item: first)
        }
    }

    /// A window that is one tab (the system's tab bar, a window each): a Space of its own, that ends with it.
    private func startAsOneTab() {
        tabs.pinned = AppFavorites.pinned
        tabs.makeContent = { makeContent($0) }
        guard tabs.workspace.isEmpty else { return }
        // A terminal that was running in another window is waiting for this one, else a saved tab of an earlier run, else a new one starts.
        if !AppActions.shared.handoff.isEmpty {
            let content = AppActions.shared.handoff.removeFirst()
            wire(content)
            tabs.adopt(content)
        } else if let saved = SessionStore.shared.take() {
            tabs.restore(saved)
        } else if !AppActions.shared.pendingSettings, AppActions.shared.pendingFiles.isEmpty {
            tabs.newTab()
        }
    }

    /// What `content` asks of a window is asked of this one: it was made here, handed here, or is drawn here from now on
    /// (a tab another window drew). A terminal takes this window's font and settings.
    func wire(_ content: any PaneContent) {
        if let model = content as? TerminalModel {
            model.wire(to: tabs)
            // Its notifications name its Space and go to it (S-e).
            model.post = { [weak model] title, body in
                if let model { AppWebNotifications.shared.post(title: title, body: body, from: model) }
            }
            configure(model)
            model.apply(font: font)
        }
        if let page = content as? WebContent { WebOpening.wire(page, in: tabs) }
        if let document = content as? DocumentContent { DocumentWiring.wire(document, in: tabs) }
        if let settings = content as? SettingsContent { settings.tabs = tabs }
    }

    func attach(_ window: NSWindow) {
        guard self.window !== window else { return }
        self.window = window
        TabRegistry.shared.register(window, tabs: tabs)
        WindowCloseGuard.install(on: window, tabs: tabs)
        AppActions.shared.joinPendingTab(window)
        if !tabs.workspace.isEmpty { AppActions.shared.finishStarting(tabs) }
        // The next window of the session opens once this one is in place, a turn of the main actor later; not from its
        // start, nor from here at once: a window opened before the one that asked for it was laid out came up at its smallest
        // size, 229 by 32 (seen 2026-11-16, three runs in three: SwiftUI's `updateAnimatedWindowSize` at the new window's first
        // layout; none in eight once it waits a turn).
        guard SessionStore.shared.hasPending else { return }
        Task { @MainActor in
            await Task.yield()
            if SessionStore.shared.hasPending { AppActions.shared.openTerminalWindow() }
        }
    }
}
