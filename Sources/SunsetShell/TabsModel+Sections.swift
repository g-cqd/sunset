/// The sections of this window's sidebars (roadmap 0031).
extension TabsModel {
    /// A key or a menu asks for `section` in the panel opposite the tabs: shown on it, or hidden when it was already showing
    /// it. `show` says which, when the asker knows.
    package func toggleOpposite(_ section: SidebarSection, show: Bool? = nil) {
        let shown = showsHistory && sections.opposite == section
        showsHistory = show ?? !shown
        if showsHistory { sections.opposite = section }
    }

    /// The section the Library shows in the tab sidebar; nil while it is closed, or not offered (`sidebar.library`).
    package func librarySection(_ settings: ShellSettings) -> SidebarSection? {
        settings.sidebar.library && sections.isLibraryOpen ? sections.library : nil
    }
}
