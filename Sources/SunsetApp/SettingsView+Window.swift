import SunsetConfig
import SwiftUI

/// The controls of the window pane (title bar, drag strip, traffic lights); the rest falls through to `moreControls`.
extension SettingsView {
    @ViewBuilder func windowControls(for id: String) -> some View {
        switch id {
            case "window.titlebar":
                Picker("Title bar", selection: config.binding(\.window.decorations)) {
                    Text("None (content under the title bar)").tag(Configuration.Window.Decorations.none)
                    Text("System").tag(Configuration.Window.Decorations.native)
                }
            case "window.dragStrip": number("Drag strip", \.window.dragStrip, range: 0 ... 64, step: 1, unit: "pt")
            case "window.lightsSide":
                Picker("Traffic lights, side", selection: config.binding(\.window.lightsSide)) {
                    Text("With the sidebar").tag(Configuration.Window.LightsSide.sidebar)
                    Text("Left").tag(Configuration.Window.LightsSide.left)
                    Text("Right (mirrored)").tag(Configuration.Window.LightsSide.right)
                }
            case "window.lightsX":
                number(
                    "Traffic lights, from their edge",
                    \.window.trafficLightsX,
                    range: 0 ... 400,
                    step: 1,
                    unit: "pt"
                )
            case "window.lightsY":
                number("Traffic lights, from the top", \.window.trafficLightsY, range: 0 ... 400, step: 1, unit: "pt")
            default: moreControls(for: id)
        }
    }
}
