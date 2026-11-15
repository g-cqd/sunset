/// Which section each sidebar of a window is on (roadmap 0031): the panel opposite the tabs, and the Library of the tab
/// sidebar, which is closed while it is on the tabs. Each is on its own section.
package struct SidebarSections: Sendable, Equatable {
    /// The section of the panel opposite the tabs: never the tabs.
    package var opposite = SidebarSection.history {
        didSet { if opposite == .tabs { opposite = oldValue } }
    }
    /// The section of the tab sidebar: the tabs while the Library is closed.
    package private(set) var library = SidebarSection.tabs
    /// What the Library opens on: the section it last showed.
    private var lastLibrary = SidebarSection.documents
    /// The documents under the Documents heading among the tabs are folded away.
    package var documentsFolded = false

    package init() {}

    package var isLibraryOpen: Bool { library != .tabs }

    /// Shows `section` in the tab sidebar; the tabs close the Library.
    package mutating func show(library section: SidebarSection) {
        library = section
        if section != .tabs { lastLibrary = section }
    }

    /// The Library's glyph: opens it where it was, or closes it.
    package mutating func toggleLibrary() { show(library: isLibraryOpen ? .tabs : lastLibrary) }

    package mutating func closeLibrary() { show(library: .tabs) }
}
