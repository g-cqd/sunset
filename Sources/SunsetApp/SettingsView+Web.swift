import SunsetConfig
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
            default:
                Picker("A page's tab shows", selection: config.binding(\.web.tabIcon)) {
                    Text("The first letter of its title").tag(Configuration.Web.TabIcon.initial)
                    Text("A globe").tag(Configuration.Web.TabIcon.globe)
                }
        }
    }
}
