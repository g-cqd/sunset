import SunsetConfig
import SunsetWeb
import SwiftUI

extension SettingsView {
    /// The web pane's options (R1).
    @ViewBuilder func webControl(for id: String) -> some View {
        switch id {
            case "web.openLinksInSunset":
                Toggle(
                    "Cmd-click on a link in a terminal opens it in a page beside it",
                    isOn: config.binding(\.web.openLinksInSunset)
                )
            case "web.developer":
                Toggle("Pages can be inspected (Inspect Element)", isOn: config.binding(\.web.developer))
            case "web.address":
                Picker("The address is typed in", selection: config.binding(\.web.address)) {
                    Text("A field at the top of the sidebar").tag(Configuration.Web.AddressPlace.sidebar)
                    Text("A bar of the window, shown at its edge").tag(Configuration.Web.AddressPlace.window)
                    Text("A row at the top of every page").tag(Configuration.Web.AddressPlace.pane)
                }
            case "web.engine":
                Picker("Words are searched with", selection: config.binding(\.web.engine)) {
                    ForEach(PaneContentKinds.webSettings.engines, id: \.name) { engine in
                        Text("\(engine.name)  (\(engine.keyword))").tag(engine.name)
                    }
                }
            case "web.suggestions":
                Toggle("Ask the engine for suggestions while typing", isOn: config.binding(\.web.suggestions))
            case "web.httpFallback":
                Toggle(
                    "Try http when https fails for a host typed without a scheme",
                    isOn: config.binding(\.web.httpFallback)
                )
            case "web.zoomScope", "web.textOnlyZoom", "web.historyKeep", "web.clearHistoryOnQuit",
                "web.clearWebsiteDataOnQuit":
                webPageControl(for: id)
            case "web.privateSuggestions":
                Toggle(
                    "Ask the engine for suggestions in private pages",
                    isOn: config.binding(\.web.privateSuggestions)
                )
            case "web.privateWindowShares":
                Toggle(
                    "The pages of a new private window share their data (a private tab of a normal window never does)",
                    isOn: config.binding(\.web.privateWindowShares)
                )
            case "web.permissions":
                WebsitesSettings(defaults: config.binding(\.web.permissions))
            case "web.engines":
                EngineList(engines: config.binding(\.web.engines))
            case "web.windowBar":
                Picker("The window bar is at the", selection: config.binding(\.web.windowBar)) {
                    Text("Top").tag(Configuration.Web.BarEdge.top)
                    Text("Bottom").tag(Configuration.Web.BarEdge.bottom)
                }
            case "web.splitBar":
                Picker("In a split, the window bar goes", selection: config.binding(\.web.splitBar)) {
                    Text("Above the panes").tag(Configuration.Web.SplitBar.margin)
                    Text("Over the focused pane").tag(Configuration.Web.SplitBar.pane)
                }
            default: tabIconPicker
        }
    }

    private var tabIconPicker: some View {
        Picker("A page's tab shows", selection: config.binding(\.web.tabIcon)) {
            Text("The site's icon").tag(Configuration.Web.TabIcon.favicon)
            Text("The first letter of its title").tag(Configuration.Web.TabIcon.initial)
            Text("A globe").tag(Configuration.Web.TabIcon.globe)
        }
    }
}
