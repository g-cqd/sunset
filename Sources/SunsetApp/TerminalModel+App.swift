import AppKit
import SunsetAppCore
import SunsetConfig
import SunsetDocuments
import SunsetHost
import SunsetMarkdown
import SunsetPane
import SunsetShell
import SunsetTerminal
import SunsetWeb

/// What a terminal asks of the app: what its programs may do, the font zoom, and the links Cmd-clicked in it (a page beside it, or the default browser,
/// by `web.openLinksInSunset`).
extension TerminalModel {
    func wire(to tabs: TabsModel) {
        hostPolicy = { HostPolicy(clipboardWrite: AppConfiguration.shared.configuration.terminal.clipboardWrite) }
        acceptsC1 = AppConfiguration.shared.configuration.terminal.c1Controls
        onZoomRequest = { AppActions.shared.zoomFont(by: $0) }
        // The system's pasteboard and whether Sunset is in front: the terminal's model knows no AppKit.
        writeClipboard = { text in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
        appIsActive = { NSApp.isActive }
        safety.settings = {
            let terminal = AppConfiguration.shared.configuration.terminal
            return (terminal.secureKeyboard, terminal.pasteWarning)
        }
        openURL = { [weak self, weak tabs] url in
            // A file of this Mac: a program is shown in the Finder, not run (ADR-0118). What Sunset opens (drawn: Markdown,
            // Mermaid, HTML, SVG; text) opens beside the terminal in a document pane when documents are on (M-h / t211).
            let links = AppConfiguration.shared.configuration.terminal.fileLinks
            if url.isFileURL {
                if links.reveals(program: FileLinkTarget.isProgram(url)) {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    return
                }
                // What the link names (an alias's target), not the alias file itself.
                let file = FileLinkTarget.target(of: url) ?? url
                if AppScopes.current.documents, let self, let tabs, Self.isSunsetDocumentURL(file) {
                    let descriptor = DocumentContent.descriptor(file: file.path)
                    if let doc = DocumentContent(descriptor, documents: SunsetStore.shared.openDocuments) {
                        if !tabs.isPrivateWindow { tabs.shelf.noteFile(file.path) }
                        DocumentWiring.wire(doc, in: tabs)
                        tabs.split(.right, with: doc, beside: self)
                        return
                    }
                }
                NSWorkspace.shared.open(url)
                return
            }
            // With the web off a link goes to the system's browser.
            guard AppConfiguration.shared.configuration.web.openLinksInSunset, AppScopes.current.web, let self, let tabs
            else {
                NSWorkspace.shared.open(url)
                return
            }
            let page = WebContent(url: url, settings: PaneContentKinds.webSettings(for: tabs))
            WebOpening.wire(page, in: tabs)
            tabs.split(.right, with: page, beside: self)
        }
    }

    private static func isSunsetDocumentURL(_ url: URL) -> Bool {
        DocumentKind.opens(path: url.path)
    }
}
