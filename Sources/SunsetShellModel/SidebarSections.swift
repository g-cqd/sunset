package import SunsetPane

/// Which section each sidebar of a window is on (roadmap 0031): the panel opposite the tabs, and the Library of the tab
/// sidebar, which is closed while it is on the tabs. Each is on its own section.
package struct SidebarSections: Sendable, Equatable {
    /// The section of the panel opposite the tabs: one of its own (never the tabs, nor the settings).
    package var opposite = SidebarSection.history {
        didSet {
            if !SidebarSection.panel.contains(opposite) { opposite = oldValue }
        }
    }
    /// The section of the tab sidebar: the tabs while the Library is closed.
    package private(set) var library = SidebarSection.tabs
    /// What the Library's glyph opens on: the list it last showed (the settings have their own way in, the gear).
    private var lastLibrary = SidebarSection.documents

    package init() {}

    package var isLibraryOpen: Bool {
        library != .tabs
    }

    /// Shows `section` in the tab sidebar; the tabs close the Library.
    package mutating func show(library section: SidebarSection) {
        library = section
        if section != .tabs, SidebarSection.rail.contains(section) { lastLibrary = section }
    }

    /// The Library's glyph: opens it where it was, or closes it.
    package mutating func toggleLibrary() {
        show(library: isLibraryOpen ? .tabs : lastLibrary)
    }

    package mutating func closeLibrary() {
        show(library: .tabs)
    }

    /// A scope of the app went off, or came back (roadmap 0033): a sidebar on a section that is not shown goes to one
    /// that is, and the Library's glyph opens one that is; with none, it opens nothing.
    package mutating func settle(for scopes: Scopes) {
        if !library.isShown(for: scopes) { library = .tabs }
        if !lastLibrary.isShown(for: scopes) || lastLibrary == .tabs {
            lastLibrary = SidebarSection.rail(for: scopes).first { $0 != .tabs } ?? .tabs
        }
        if !opposite.isShown(for: scopes), let first = SidebarSection.panel(for: scopes).first { opposite = first }
    }
}
