import SunsetConfig
import SunsetHelp
import SunsetShell
import SwiftUI

/// A setting that can differ between light and dark (design 0009), on one line: its title, its control, and a light and
/// dark button beside it. Pressed, the row shows two controls, light's and dark's, each under its symbol; pressed again,
/// one for both. An option whose light value is always apart (`lightTwin`: the tint's) shows both, with no button.
struct SchemeSettingsRow: View {
    let option: SettingsOption
    let config: any SettingsStore

    private var twin: SettingsOption? {
        option.lightTwin.flatMap { id in SettingsOption.all.first { $0.id == id } }
    }

    private var separate: Bool {
        twin != nil || config.configuration.lightValues[option.id] != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.xs) {
            LabeledContent {
                HStack(spacing: Design.Space.m) {
                    if separate {
                        // Light first, as the system lists them.
                        scheme(light: true) {
                            if let twin { control(twin, config) } else { control(option, lightStore) }
                        }
                        scheme(light: false) { control(option, config) }
                    } else {
                        control(option, config)
                    }
                    if twin == nil { splitButton }
                }
            } label: {
                SettingsLabel(option.title, help: HelpTopic.explaining(setting: option.id))
            }
            if let note = option.note {
                Text(RichText.attributed(note)).font(Design.Text.detail).foregroundStyle(.secondary)
            }
        }
    }

    private var lightStore: LightSettingsStore {
        LightSettingsStore(base: config, key: option.id)
    }

    /// The option's control alone: its row with its title hidden.
    private func control(_ option: SettingsOption, _ store: any SettingsStore) -> some View {
        SettingsRow(option: option.unnoted, config: store).labelsHidden().fixedSize()
    }

    /// A control under the scheme it sets: a sun for light, a moon for dark.
    private func scheme(light: Bool, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: Design.Space.xs) {
            Image(systemName: light ? "sun.max" : "moon")
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            content()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(light ? "In light" : "In dark")
    }

    /// One value for both, or one each: the light value starts as the current one; one for both keeps the dark one.
    private var splitButton: some View {
        Button {
            let key = option.id
            let on = !separate
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
