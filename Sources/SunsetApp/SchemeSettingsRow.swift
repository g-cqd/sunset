import SunsetConfig
import SunsetShell
import SwiftUI

/// A setting that can differ between light and dark (design 0009): one control, or with "Separate for light and dark"
/// on, one for each, the dark one its own value and the light one its light value.
struct SchemeSettingsRow: View {
    let option: SettingsOption
    let config: any SettingsStore

    private var separate: Bool {
        config.configuration.lightValues[option.id] != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.xs) {
            if separate {
                SettingsRow(option: option.titled("\(option.title) in dark"), config: config)
                SettingsRow(
                    option: option.titled("\(option.title) in light").unnoted,
                    config: LightSettingsStore(base: config, key: option.id)
                )
            } else {
                SettingsRow(option: option, config: config)
            }
            Toggle("Separate for light and dark", isOn: binding)
                .toggleStyle(.checkbox)
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
        }
    }

    /// On: the light value starts as the current one; off: the light value goes, the dark one is kept for both.
    private var binding: Binding<Bool> {
        Binding(
            get: { separate },
            set: { on in
                let key = option.id
                config.update { configuration in
                    configuration.lightValues[key] = on ? Configuration.literal(of: key, in: configuration) : nil
                }
            }
        )
    }
}
