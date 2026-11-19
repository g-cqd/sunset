import AppKit
import SunsetHost
import SunsetMarkdown
import SunsetPane
import SunsetShell

/// Documents (roadmap 0023 step M-c): opening a file in a tab, and what the menus do to the document pane in front.
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

    /// Opens files (the Open panel, a drop, Finder, the command bar) in the window that acts: each in a tab of its own, one
    /// that window already shows is shown. With no window (Sunset was started by opening them, or its last window is closed)
    /// one is opened for them: SwiftUI makes none for a file (`handlesExternalEvents(matching: [])`, ADR-0040), and AppKit
    /// makes no first window for a Sunset started on one.
    func open(files paths: [String]) {
        // With documents off Sunset shows no file: each goes to the app that opens it by default (roadmap 0033).
        guard AppScopes.current.documents else { return AppScopes.openElsewhere(paths) }
        // A window that is not on screen yet (Sunset is starting, or is behind) is not the one that acts: any window will do.
        let acting = TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow)
        guard let tabs = acting ?? TabRegistry.shared.allWindows().first?.tabs, !tabs.workspace.isEmpty else {
            let asked = !pendingFiles.isEmpty
            pendingFiles += paths
            // One window for all of them, however many times the system says "open these" before it is there.
            if !asked, TabRegistry.shared.allWindows().isEmpty {
                tabParent = nil
                joinsRemaining = 0
                openTerminalWindow()
            }
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
