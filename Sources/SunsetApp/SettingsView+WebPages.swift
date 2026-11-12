import SunsetConfig
import SwiftUI

extension SettingsView {
    /// Zoom and history (web steps d and e).
    @ViewBuilder func webPageControl(for id: String) -> some View {
        switch id {
            case "web.zoomScope":
                Picker("A page's zoom applies to", selection: config.binding(\.web.zoomScope)) {
                    Text("Its site, remembered").tag(Configuration.Web.ZoomScope.site)
                    Text("Its site, until Sunset quits").tag(Configuration.Web.ZoomScope.session)
                    Text("The page alone, saved with it").tag(Configuration.Web.ZoomScope.page)
                }
            case "web.textOnlyZoom":
                if WebTextZoomProbe.isAvailable {
                    Toggle("Zoom makes only the text bigger", isOn: config.binding(\.web.textOnlyZoom))
                }
            case "web.historyKeep":
                Picker("Keep the history of pages for", selection: config.binding(\.web.historyKeep)) {
                    Text("One day").tag(Configuration.Web.HistoryKeep.day)
                    Text("One week").tag(Configuration.Web.HistoryKeep.week)
                    Text("Two weeks").tag(Configuration.Web.HistoryKeep.twoWeeks)
                    Text("One month").tag(Configuration.Web.HistoryKeep.month)
                    Text("One year").tag(Configuration.Web.HistoryKeep.year)
                    Text("Always").tag(Configuration.Web.HistoryKeep.forever)
                }
            case "web.clearHistoryOnQuit":
                Toggle("Clear the history when Sunset quits", isOn: config.binding(\.web.clearHistoryOnQuit))
            default:
                Toggle(
                    "Clear website data when Sunset quits (signs you out of sites)",
                    isOn: config.binding(\.web.clearWebsiteDataOnQuit)
                )
        }
    }
}
