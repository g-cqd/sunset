import AppKit
import SunsetHost
import SunsetMarkdown
import SunsetPane
import SunsetShell

/// Documents: opening a file in a tab, and what the menus do to the document pane in front.
extension AppActions {
    /// The document pane the menus act on: the one shown in the acting window.
    var frontDocument: DocumentContent? {
        TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)?.selectedContent as? DocumentContent
    }

    /// File > Open File (Cmd-O): each file chosen opens in a tab of its own. Markdown and Mermaid are drawn; any other text is
    /// shown as source; what is not text says so in its pane.
    func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.message = "Markdown and Mermaid files are drawn; any other text file opens as source."
        guard panel.runModal() == .OK else { return }
        open(files: panel.urls.map(\.path))
    }

    /// A tab on the file at `path`.
    func openDocument(at path: String) {
        open(files: [path])
    }

    /// The tabs what comes from outside opens in: the window that acts, else any window (one not on screen yet, Sunset
    /// starting or behind, is not the one that acts). None while no window is ready: then one is opened, once for all that
    /// come before it is there (`alreadyAsked`). A window is ready once it has started, tabs or not: one that showed only
    /// its Favorites and Pinned tabs (no tab of Today) was taken for one not ready, and every file opened after waited for
    /// a window that never came (the owner, 2026-11-27: no Markdown or text file opened any more, from anywhere).
    func incomingTabs(alreadyAsked: Bool) -> TabsModel? {
        let acting = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)
        if let tabs = acting ?? TabRegistry.shared.allWindows().first?.tabs, tabs.started || !tabs.workspace.isEmpty {
            return tabs
        }
        if !alreadyAsked, TabRegistry.shared.allWindows().isEmpty {
            tabParent = nil
            joinsRemaining = 0
            openTerminalWindow()
        }
        return nil
    }

    /// Opens files (the Open panel, a drop, Finder, the command bar) in the window that acts: each in a tab of its own, one
    /// that window already shows is shown. With no window (Sunset was started by opening them, or its last window is closed)
    /// one is opened for them: SwiftUI makes none for a file (`handlesExternalEvents(matching: [])`), and AppKit makes no
    /// first window for a Sunset started on one.
    func open(files paths: [String]) {
        // With documents off Sunset shows no file: each goes to the app that opens it by default.
        guard AppScopes.current.documents else { return AppScopes.openElsewhere(paths) }
        guard let tabs = incomingTabs(alreadyAsked: !pendingFiles.isEmpty) else {
            pendingFiles += paths
            return
        }
        guard AppConfiguration.shared.presentation.hostsTabsInWindow else {
            for path in paths {
                if !tabs.isPrivateWindow { tabs.shelf.noteFile(path) }
                newTab(kind: DocumentContent.descriptor(file: path))
            }
            return
        }
        tabs.open(files: paths)
    }

    /// A window has its tabs: the files that waited for one open in it, and the settings when they were asked for with no
    /// window open (Cmd-,).
    func finishStarting(_ tabs: TabsModel) {
        openPendingPages(in: tabs)
        if pendingSettings {
            pendingSettings = false
            AppSettings.show(in: tabs)
        }
        guard !pendingFiles.isEmpty else { return }
        let files = pendingFiles
        pendingFiles = []
        tabs.open(files: files)
    }
}
