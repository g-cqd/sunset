import SunsetConfig
import SunsetShell
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
            case "cursor.shape":
                VStack(alignment: .leading, spacing: 4) {
                    Picker("Cursor shape", selection: config.binding(\.cursorShape)) {
                        Text("Block").tag(Configuration.CursorShape.block)
                        Text("Underline").tag(Configuration.CursorShape.underline)
                        Text("Bar").tag(Configuration.CursorShape.bar)
                    }
                    Text(
                        "What programs get unless they choose their own cursor (an editor often does); they get it back when they ask for the default."
                    )
                    .font(Design.Text.detail).foregroundStyle(.secondary)
                }
            case "cursor.blink": Toggle("Cursor blinks", isOn: config.binding(\.cursorBlinks))
            default: moreControls(for: id)
        }
    }
}
