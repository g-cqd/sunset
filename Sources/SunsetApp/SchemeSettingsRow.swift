import SunsetConfig
import SunsetHelp
import SunsetShell
import SwiftUI

/// A look setting (design 0009): its value in the scheme Settings shows. System's is macOS's, read only; light's or dark's
/// is Sunset's there, with a button that puts macOS's back once it was changed.
struct SchemeSettingsRow: View {
    let option: SettingsOption
    let config: any SettingsStore
    let editing: SchemeEditing
    /// The scheme shown is light.
    let light: Bool

    private static let resetHelp = "Use the system's value in this scheme"

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.xs) {
            if case .custom = option.control {
                // A control of its own (the palette) under its title, the button at its side.
                HStack(alignment: .top) {
                    control.disabled(editing == .system)
                    Spacer()
                    reset
                }
            } else {
                LabeledContent {
                    HStack(spacing: Design.Space.s) {
                        reset
                        control.labelsHidden().fixedSize().disabled(editing == .system)
                    }
                } label: {
                    SettingsLabel(option.title, help: HelpTopic.explaining(setting: option.id))
                }
            }
            if let note = option.note {
                Text(RichText.attributed(note)).font(Design.Text.detail).foregroundStyle(.secondary)
            }
        }
    }

    private var control: some View {
        SettingsRow(option: option.unnoted, config: Self.store(config, option.id, editing, light))
    }

    /// Puts the system's value back, once it was changed in the scheme shown.
    @ViewBuilder private var reset: some View {
        if changed {
            Button {
                let key = option.id
                let light = light
                config.update { $0.resetToNative(key, light: light) }
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.borderless)
            .help(Self.resetHelp)
            .accessibilityLabel(Self.resetHelp)
        }
    }

    /// Changed in the scheme shown: not the system's there.
    private var changed: Bool {
        editing != .system && config.configuration.changes(option.id, light: light)
    }

    /// Where the control of `key` reads and writes in a scheme: macOS's (nowhere), light's, or the configuration's own.
    static func store(_ config: any SettingsStore, _ key: String, _ editing: SchemeEditing, _ light: Bool)
        -> any SettingsStore
    {
        switch editing {
            case .system: LightSettingsStore(base: config, .native(light: light))
            case .light: LightSettingsStore(base: config, .light(key: key))
            case .dark: config
        }
    }
}
