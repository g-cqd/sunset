import AppKit
import SunsetMarkdown
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
        for url in panel.urls { openDocument(at: url.path) }
    }

    /// A tab on the file at `path`.
    func openDocument(at path: String) { newTab(kind: DocumentContent.descriptor(file: path)) }
}
