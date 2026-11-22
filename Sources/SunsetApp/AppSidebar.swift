import SunsetConfig
import SunsetHelp
import SunsetMetrics
import SunsetPane
import SunsetShell
import SunsetShellBridge
import SunsetWeb
import SwiftUI

/// What the tab sidebar shows, docked or floating: the tabs, or the Library on one of its sections. Opening the Library
/// widens the sidebar in place: the rail comes at the window's edge past a gutter, and what the list shows changes where
/// it is. The tabs stay as they are underneath (their scroll, their rows), unseen and out of reach, so that going back
/// does not make them again.
struct AppSidebar: View {
    let tabs: TabsModel
    let configuration: Configuration
    var floating = false
    var panelRadius: Double?
    /// The window's corner radius: docked, the button at its bottom corner is concentric with it.
    var windowRadius = ConcentricRadius.standardWindow
    var accessory: AnyView?
    /// The calls to action under it.
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
                },
                // Where it is above the Library's glyph with the Library closed.
                downloads: DownloadCenter.shared.items.isEmpty ? nil : AnyView(DownloadsButton())
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
            bottomBarRows: SidebarBottomBar.rows(
                library: configuration.sidebar.library && SidebarSection.rail(for: tabs.scopes).count > 1,
                downloads: !DownloadCenter.shared.items.isEmpty
            ),
            footer: nowPlaying,
            headerExtras: extensionButtons,
            togglePin: AppConfiguration.togglePin
        )
    }

    /// What plays, above the bar (`web.nowPlaying`; roadmap 0114); Go There shows its tab, in its Space and window.
    private var nowPlaying: AnyView? {
        guard configuration.web.nowPlaying, !NowPlaying.shared.stack.pages.isEmpty else { return nil }
        return AnyView(
            NowPlayingStack(pictureInPicture: configuration.web.pictureInPicture) { page in
                AppWebNotifications.shared.reveal(page)
            }
        )
    }

    /// What the header leaves between the pin and the traffic lights: the sidebar's width, less its side gaps, the pin and the
    /// lights' room.
    private var extensionsWidth: Double {
        let settings = ShellSettings(configuration)
        let buttons = SidebarButtons(
            layout: settings.layout,
            margin: configuration.sidebar.padding,
            panelRadius: panelRadius
        )
        return configuration.sidebar.width - 2 * buttons.gap - buttons.metrics.size.width - Design.Space.xs
            - Design.TabCapsules.lightsClearance
    }

    /// The window's profile's extensions, beside the pin: with the web on and one installed and on.
    private var extensionButtons: AnyView? {
        guard tabs.scopes.web, let host = ExtensionHosts.shared.host(for: PaneContentKinds.profile(of: tabs)),
            host.installed.contains(where: \.enabled)
        else { return nil }
        return AnyView(
            ExtensionActionsBar(host: host, page: tabs.selectedContent as? WebContent, width: extensionsWidth) {
                AppSettings.show("web.extensions", in: tabs)
            }
        )
    }
}
