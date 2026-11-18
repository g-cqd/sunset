import SunsetConfig
import SunsetHelp
import SunsetMetrics
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// What the tab sidebar shows, docked or floating: the tabs, or the Library on one of its sections (roadmap 0031). Opening the
/// Library widens the sidebar in place (the owner, 2026-11-15): the rail comes at the window's edge past a gutter, and what
/// the list shows changes where it is. The tabs stay as they are underneath (their scroll, their rows), unseen and out of
/// reach, so that going back does not make them again.
struct AppSidebar: View {
    let tabs: TabsModel
    let configuration: Configuration
    var floating = false
    var panelRadius: Double?
    /// The window's corner radius: docked, the button at its bottom corner is concentric with it.
    var windowRadius = ConcentricRadius.standardWindow
    var accessory: AnyView?
    /// The calls to action under it (roadmap 0035 I).
    var notices: AnyView?

    var body: some View {
        let settings = ShellSettings(configuration)
        let section = tabs.librarySection(settings)
        let buttons = SidebarButtons(
            layout: floating ? settings.layout.floatingTabs : settings.layout,
            margin: settings.sidebar.padding,
            panelRadius: panelRadius,
            windowRadius: windowRadius
        )
        LibraryFrame(railLeading: settings.sidebar.side == .left, buttons: buttons, railShown: section != nil) {
            ZStack {
                tabList(settings)
                    .opacity(section == nil ? 1 : 0)
                    .allowsHitTesting(section == nil)
                    .accessibilityHidden(section != nil)
                if let section {
                    LibrarySidebar(tabs: tabs, settings: settings, section: section, buttons: buttons)
                        .transition(.opacity)
                }
            }
        } rail: {
            SectionRail(
                selection: section ?? .tabs,
                sections: settings.sidebar.library ? SidebarSection.rail(for: tabs.scopes) : [],
                buttons: buttons,
                leading: settings.sidebar.side == .left,
                help: {
                    // On the settings' page shown, its topic; elsewhere, where Help was.
                    let page = section == .settings ? AppSettings.content(in: tabs)?.topic : nil
                    AppHelp.show(HelpTree.topic(about: page), in: tabs)
                }
            ) { chosen in
                if chosen == .settings { AppSettings.show(in: tabs) } else { tabs.sections.show(library: chosen) }
            }
        }
    }

    private func tabList(_ settings: ShellSettings) -> some View {
        TabSidebar(
            tabs: tabs,
            settings: settings,
            floating: floating,
            panelRadius: panelRadius,
            windowRadius: windowRadius,
            accessory: accessory,
            notices: notices,
            bottomBar: AnyView(
                SidebarBottomBar(
                    side: configuration.sidebar.side,
                    tabs: tabs,
                    library: configuration.sidebar.library,
                    spacing: settings.layout.tabSpacing
                )
            ),
            togglePin: AppConfiguration.togglePin
        )
    }
}
