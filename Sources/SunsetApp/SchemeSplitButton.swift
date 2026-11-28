import SunsetConfig
import SunsetShell
import SwiftUI

/// One value for both schemes, or one each (design 0009): the light value starts as the current one; one for both keeps
/// the dark one.
struct SchemeSplitButton: View {
    let key: String
    let config: any SettingsStore
    let separate: Bool

    var body: some View {
        Button {
            let on = !separate
            let key = key
            config.update { configuration in
                configuration.lightValues[key] = on ? Configuration.literal(of: key, in: configuration) : nil
            }
        } label: {
            Image(systemName: "circle.lefthalf.filled")
                .foregroundStyle(separate ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Separate for light and dark")
        .accessibilityValue(separate ? "On" : "Off")
    }
}
