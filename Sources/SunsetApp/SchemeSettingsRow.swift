import SunsetConfig
import SunsetHelp
import SunsetShell
import SwiftUI

/// A look setting (design 0009) on one line: its title, then its value in light and in dark, each under its symbol. Each
/// is macOS's until changed in that scheme.
struct SchemeSettingsRow: View {
    let option: SettingsOption
    let config: any SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.xs) {
            LabeledContent {
                HStack(spacing: Design.Space.m) {
                    // Light first, as the system lists them.
                    SchemeLabeled(light: true) { control(LightSettingsStore(base: config, key: option.id)) }
                    SchemeLabeled(light: false) { control(config) }
                }
            } label: {
                SettingsLabel(option.title, help: HelpTopic.explaining(setting: option.id))
            }
            if let note = option.note {
                Text(RichText.attributed(note)).font(Design.Text.detail).foregroundStyle(.secondary)
            }
        }
    }

    /// The option's control alone: its row with its title hidden.
    private func control(_ store: any SettingsStore) -> some View {
        SettingsRow(option: option.unnoted, config: store).labelsHidden().fixedSize()
    }
}
