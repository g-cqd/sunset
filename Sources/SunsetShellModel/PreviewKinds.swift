import SunsetPane

/// Which rows show a preview card when pointed at (`sidebar.previews`, `sidebar.previewPages` and the rest): all, none, or by kind. A tab shows one when one of its panes' kinds does.
package struct PreviewKinds: Sendable, Equatable {
    package var enabled = true
    package var pages = true
    package var terminals = true
    package var documents = true
    package var folders = true

    package init() {}

    /// Whether a tab whose panes are of `kinds` shows a card.
    package func shows(kinds: [String]) -> Bool {
        enabled
            && kinds.contains { kind in
                switch kind {
                    case "web": pages
                    case PaneDescriptor.terminalKind: terminals
                    case PaneDescriptor.documentKind: documents
                    default: true
                }
            }
    }

    /// Whether a folder of the Favorites shows its card.
    package var showsFolders: Bool {
        enabled && folders
    }
}
