import SunsetConfig
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// What the tab sidebar shows, docked or floating: the tabs, or the Library on one of its sections (roadmap 0031).
struct AppSidebar: View {
    let tabs: TabsModel
    let configuration: Configuration
    var floating = false
    var panelRadius: Double?
    var accessory: AnyView?

    var body: some View {
        let settings = ShellSettings(configuration)
        if let section = tabs.librarySection(settings) {
            LibrarySidebar(
                tabs: tabs,
                settings: settings,
                section: section,
                floating: floating,
                panelRadius: panelRadius,
                togglePin: AppConfiguration.togglePin
            )
        } else {
            TabSidebar(
                tabs: tabs,
                settings: settings,
                floating: floating,
                panelRadius: panelRadius,
                accessory: accessory,
                bottomBar: AnyView(
                    SidebarBottomBar(
                        side: configuration.sidebar.side,
                        tabs: tabs,
                        library: configuration.sidebar.library
                    )
                ),
                togglePin: AppConfiguration.togglePin
            )
        }
    }
}
