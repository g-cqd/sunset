import SunsetConfig
import SunsetShell

/// The sections of the sidebars (roadmap 0031), from the menus.
extension AppActions {
    private var actingTabs: TabsModel? { TabRegistry.shared.tabs(for: TabRegistry.shared.actingWindow) }

    /// View > Library: the tab sidebar's Library, opened where it was or closed. Nothing while `sidebar.library` is off.
    func toggleLibrary() {
        guard AppConfiguration.shared.configuration.sidebar.library else { return }
        actingTabs?.sections.toggleLibrary()
    }

    /// View > Documents, Downloads: the panel opposite the tabs on that section, or hidden when it was showing it.
    func toggleOpposite(_ section: SidebarSection) { actingTabs?.toggleOpposite(section) }

    /// File > New Document: a document of the store, opened on its row. Nothing when none can be kept in this run.
    func newDocument() { actingTabs?.newDocument() }
}
