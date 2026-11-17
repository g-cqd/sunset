import AppKit
import SunsetMarkdown
import SunsetPane
import SunsetShell
import SunsetWeb

/// Where what a document pane opens goes, and what its changes save. Show Beside, beside; a link, where the keys held and
/// `documents.linksOpen` say (the owner, 2026-11-17; R6 had "everything in a new split").
@MainActor enum DocumentWiring {
    /// Gives `content` its way of placing what it opens, in the window `tabs`, and of saving which view it shows.
    static func wire(_ content: DocumentContent, in tabs: TabsModel) {
        content.onChange = { SessionStore.shared.scheduleSave() }
        content.onOpen = { [weak tabs, weak content] opening, place in
            guard let tabs, let content else { return }
            switch opening {
                case .document(let other):
                    // A link to another file: opened lately too, but not from a private window.
                    if !tabs.isPrivateWindow, other.document !== content.document,
                        let file = other.descriptor.documentFile
                    {
                        tabs.shelf.noteFile(file)
                    }
                    wire(other, in: tabs)
                    put(other, place, beside: content, in: tabs)
                case .web(let url) where !AppScopes.current.web: NSWorkspace.shared.open(url)
                case .web(let url):
                    // In a private window the page is private, as any page made there is.
                    let privacy = tabs.privateGroup.map { tabs.privateShares ? PagePrivacy(group: $0) : PagePrivacy() }
                    let wanted = PaneDescriptor(kind: WebContent.kind, state: ["url": url.absoluteString])
                    // With the website data of the Space's profile, as any page made there.
                    let profile = PaneContentKinds.profile(of: tabs)
                    let page = PaneContentKinds.make(wanted, privacy: privacy, profile: profile) {
                        SessionStore.shared.scheduleSave()
                    }
                    if let page = page as? WebContent { WebOpening.wire(page, in: tabs) }
                    put(page, place, beside: content, in: tabs)
                case .system(let url): NSWorkspace.shared.open(url)
            }
        }
    }

    /// Puts what a document opened where `place` says.
    private static func put(
        _ opened: any PaneContent,
        _ place: LinkPlace,
        beside content: DocumentContent,
        in tabs: TabsModel
    ) {
        switch place {
            case .beside: tabs.split(.right, with: opened, beside: content)
            case .tab: tabs.insertTab(opened, after: content, show: true)
            case .backgroundTab: tabs.insertTab(opened, after: content, show: false)
            case .window:
                AppActions.shared.handoff.append(opened)
                AppActions.shared.openTerminalWindow()
        }
    }
}
