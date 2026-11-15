import AppKit
import SunsetMarkdown
import SunsetPane
import SunsetShell
import SunsetWeb

/// Where what a document pane opens goes (R6: "everything in a new split"), and what its changes save.
@MainActor enum DocumentWiring {
    /// Gives `content` its way of placing what it opens, in the window `tabs`, and of saving which view it shows.
    static func wire(_ content: DocumentContent, in tabs: TabsModel) {
        content.onChange = { SessionStore.shared.scheduleSave() }
        content.onOpen = { [weak tabs, weak content] opening in
            guard let tabs, let content else { return }
            switch opening {
                case .document(let other):
                    wire(other, in: tabs)
                    tabs.split(.right, with: other, beside: content)
                case .web(let url):
                    // In a private window the page is private, as any page made there is.
                    let privacy = tabs.privateGroup.map { tabs.privateShares ? PagePrivacy(group: $0) : PagePrivacy() }
                    let wanted = PaneDescriptor(kind: WebContent.kind, state: ["url": url.absoluteString])
                    let page = PaneContentKinds.make(wanted, privacy: privacy) { SessionStore.shared.scheduleSave() }
                    if let page = page as? WebContent { WebOpening.wire(page, in: tabs) }
                    tabs.split(.right, with: page, beside: content)
                case .system(let url): NSWorkspace.shared.open(url)
            }
        }
    }
}
