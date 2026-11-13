import SunsetConfig
import SwiftUI

/// The window's tint, in the dark scheme and in the light one.
extension SettingsView {
    @ViewBuilder func tintControls(for id: String) -> some View {
        switch id {
            case "appearance.tint": colorRow("Tint", \.appearance.tintColor, fallback: [48, 96, 255])
            case "appearance.tintLight":
                colorRow("Tint in the light scheme", \.appearance.lightTintColor, fallback: [255, 255, 255])
            case "appearance.tintLightAlpha":
                number(
                    "Tint strength in the light scheme",
                    \.appearance.lightTintAlpha,
                    range: 0 ... 1,
                    step: 0.05,
                    unit: ""
                )
            default: number("Tint strength", \.appearance.tintAlpha, range: 0 ... 1, step: 0.05, unit: "")
        }
    }
}
