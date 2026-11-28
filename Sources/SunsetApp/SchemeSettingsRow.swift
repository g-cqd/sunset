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
                        SchemeLabeled(light: true) {
                            if let twin { control(twin, config) } else { control(option, lightStore) }
                        }
                        SchemeLabeled(light: false) { control(option, config) }
                    } else {
                        control(option, config)
                    }
                    if twin == nil { SchemeSplitButton(key: option.id, config: config, separate: separate) }
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
}
