import SunsetMetrics
import SunsetShell
import SwiftUI

/// The tab sidebar while the Library is open (roadmap 0031, the owner's choice L2): the rail of sections on the window's edge
/// side, and the section shown beside it; the sidebar is wider by the rail. The way back to the tabs: the Tabs glyph, the
/// arrow at the rail's foot (where the Library's glyph was), and Escape while the keyboard is in the Library.
struct LibrarySidebar: View {
    let tabs: TabsModel
    let settings: ShellSettings
    let section: SidebarSection
    var floating = false
    var panelRadius: Double?
    let togglePin: () -> Void

    private var buttons: SidebarButtons {
        SidebarButtons(
            layout: floating ? settings.layout.floatingTabs : settings.layout,
            margin: settings.sidebar.padding,
            panelRadius: panelRadius
        )
    }

    /// How much wider the sidebar is while the Library is open.
    static func extraWidth(_ tabs: TabsModel, _ settings: ShellSettings, floating: Bool) -> Double {
        guard tabs.librarySection(settings) != nil else { return 0 }
        let layout = floating ? settings.layout.floatingTabs : settings.layout
        return SectionRail.width(
            SidebarButtons(layout: layout, margin: settings.sidebar.padding, panelRadius: floating ? 0 : nil)
        )
    }

    var body: some View {
        let left = settings.sidebar.side == .left
        HStack(spacing: 0) {
            if left { rail }
            SectionPanel(
                tabs: tabs,
                section: section,
                buttons: buttons,
                sort: settings.sidebar.documentSort,
                place: .library
            )
            if !left { rail }
        }
        .overlay(alignment: left ? .topTrailing : .topLeading) {
            SidebarPinButton(sidebar: settings.sidebar, buttons: buttons, toggle: togglePin)
        }
        .onExitCommand { tabs.sections.closeLibrary() }
    }

    private var rail: some View {
        SectionRail(
            selection: section,
            sections: settings.sidebar.library ? SidebarSection.rail : [],
            buttons: buttons
        ) { chosen in
            if chosen == .settings { AppSettings.show(in: tabs) } else { tabs.sections.show(library: chosen) }
        }
        .padding(settings.sidebar.side == .left ? .leading : .trailing, buttons.gap)
    }
}
