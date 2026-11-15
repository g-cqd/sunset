import SunsetMetrics
import SunsetShell
import SwiftUI

/// The list of the tab sidebar while the Library is open (roadmap 0031, the owner's choice L2): the section shown, where the
/// tabs were, with the pin where the tabs have it. The rail of sections is beside it (`AppSidebar`, `LibraryFrame`). The way
/// back to the tabs: the Tabs glyph, the arrow at the rail's foot (where the Library's glyph was), and Escape while the
/// keyboard is in the Library.
struct LibrarySidebar: View {
    let tabs: TabsModel
    let settings: ShellSettings
    let section: SidebarSection
    let buttons: SidebarButtons

    /// How much wider the sidebar is while the Library is open: its rail and the gutter.
    static func extraWidth(_ tabs: TabsModel, _ settings: ShellSettings, floating: Bool) -> Double {
        guard tabs.librarySection(settings) != nil else { return 0 }
        let layout = floating ? settings.layout.floatingTabs : settings.layout
        return SectionRail.width(
            SidebarButtons(layout: layout, margin: settings.sidebar.padding, panelRadius: floating ? 0 : nil)
        )
    }

    var body: some View {
        SectionPanel(
            tabs: tabs,
            section: section,
            buttons: buttons,
            sort: settings.sidebar.documentSort,
            place: .library
        )
        .overlay(alignment: settings.sidebar.side == .left ? .topTrailing : .topLeading) {
            SidebarPinButton(sidebar: settings.sidebar, buttons: buttons, toggle: AppConfiguration.togglePin)
        }
        .onExitCommand { tabs.sections.closeLibrary() }
    }
}
