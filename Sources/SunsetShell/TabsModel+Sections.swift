/// The sections of this window's sidebars (roadmap 0031).
extension TabsModel {
    /// A key or a menu asks for `section` in the panel opposite the tabs: shown on it, or hidden when it was already showing
    /// it. `show` says which, when the asker knows.
    package func toggleOpposite(_ section: SidebarSection, show: Bool? = nil) {
        let shown = showsHistory && sections.opposite == section
        showsHistory = show ?? !shown
        if showsHistory { sections.opposite = section }
    }

    /// The section shown in the tab sidebar instead of the tabs; nil while it shows the tabs. The Library's lists are offered by
    /// `sidebar.library`; the settings' list is not the Library's to hide.
    package func librarySection(_ settings: ShellSettings) -> SidebarSection? {
        guard sections.isLibraryOpen else { return nil }
        return settings.sidebar.library || sections.library == .settings ? sections.library : nil
    }

    /// Whether the page of the settings carries its own list of sections and topics (roadmap 0032): always, but when the docked
    /// sidebar shows that list. A sidebar that hides, or none, cannot be counted on to move between topics.
    package func settingsListInPage(sidebarDocked: Bool) -> Bool {
        !(sidebarDocked && sections.library == .settings)
    }
}
