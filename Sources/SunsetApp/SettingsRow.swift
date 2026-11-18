import SunsetConfig
import SunsetHelp
import SunsetShell
import SwiftUI

/// One option of Settings, drawn from its declaration (`SettingsOption`): its control by kind, and its note under it. There is
/// no lookup by name: an option cannot show another's control.
struct SettingsRow: View {
    let option: SettingsOption
    let config: AppConfiguration

    var body: some View {
        if let note = option.note {
            VStack(alignment: .leading, spacing: Design.Space.xs) {
                explained
                Text(RichText.attributed(note)).font(Design.Text.detail).foregroundStyle(.secondary)
            }
        } else {
            explained
        }
    }

    /// A list's rows, for its own section: its title and note are the section's.
    @ViewBuilder static func list(_ option: SettingsOption, config: AppConfiguration, heading: String? = nil)
        -> some View
    {
        if option.ownsSections, case .custom(.sites) = option.control {
            SitesSettings(heading: heading, config: config)
        } else if option.ownsSections {
            ProfilesSettings(heading: heading, title: option.title, note: option.note)
        } else if case .custom(let custom) = option.control {
            SettingsCustomRow(custom: custom, option: option, config: config)
        }
    }

    private var help: HelpTopic? { HelpTopic.explaining(setting: option.id) }

    /// The title on the leading edge with its "?" beside it, the control on the trailing edge (the owner, 2026-11-18): every
    /// control of a page lines up on one edge, every title on the other.
    @ViewBuilder private var explained: some View {
        switch option.control {
            case .toggle(let value, let label):
                LabeledContent {
                    Toggle(label ?? option.title, isOn: config.binding(value)).labelsHidden()
                } label: {
                    SettingsLabel(label ?? option.title, help: help)
                }
            case .number(let value, let range, let step, let unit, let digits):
                NumberRow(
                    name: option.title,
                    value: config.binding(value),
                    range: range,
                    step: step,
                    unit: unit,
                    fractionDigits: digits,
                    help: help
                )
            case .choice(let choice, let label):
                LabeledContent {
                    Picker(label ?? option.title, selection: binding(choice)) {
                        ForEach(choice.items, id: \.value) { Text($0.label).tag($0.value) }
                    }
                    .labelsHidden()
                    .fixedSize()
                } label: {
                    SettingsLabel(label ?? option.title, help: help)
                }
            case .text(let value, let prompt):
                LabeledContent {
                    HStack(spacing: Design.Space.s) {
                        TextField(option.title, text: config.binding(value), prompt: Text(prompt)).labelsHidden()
                            .code(option.isCode)
                        // A folder: the system's panel too (the owner's note n36).
                        if option.isFolder { FolderPicker(title: option.title, path: config.binding(value)) }
                    }
                } label: {
                    SettingsLabel(option.title, help: help)
                }
            case .optionalText(let value, let prompt):
                LabeledContent {
                    TextField(option.title, text: config.textBinding(value), prompt: Text(prompt)).labelsHidden()
                        .code(option.isCode)
                } label: {
                    SettingsLabel(option.title, help: help)
                }
            case .color(let value, let fallback): colorRow(value, fallback: fallback)
            case .radius(let value): radiusRow(value)
            case .custom(let custom): SettingsCustomRow(custom: custom, option: option, config: config)
        }
    }

    private func binding(_ choice: SettingsChoice) -> Binding<String> {
        Binding(
            get: { choice.get(config.configuration) },
            set: { raw in config.update { choice.set(&$0, raw) } }
        )
    }

    /// A colour that can be left unset: a switch, and a well that is live while it is on.
    private func colorRow(_ value: SettingsValue<[UInt8]?>, fallback: [UInt8]) -> some View {
        LabeledContent {
            HStack {
                Toggle("Custom", isOn: config.switchBinding(value, whenOn: fallback)).labelsHidden()
                ColorPicker(
                    option.title,
                    selection: config.colorBinding(value, fallback: fallback),
                    supportsOpacity: false
                )
                .labelsHidden()
                .disabled(value.get(config.configuration) == nil)
            }
        } label: {
            SettingsLabel(option.title, help: help)
        }
    }

    /// A radius that is either the window's (concentric: its radius minus the margin) or a number of points of its own.
    private func radiusRow(_ value: SettingsValue<Double?>) -> some View {
        let follows = Binding(
            get: { value.get(config.configuration) == nil },
            set: { follow in config.update { value.set(&$0, follow ? nil : 10) } }
        )
        let points = Binding(
            get: { value.get(config.configuration) ?? 10 },
            set: { new in config.update { value.set(&$0, new) } }
        )
        return VStack(alignment: .leading, spacing: Design.Space.xs) {
            LabeledContent {
                Toggle("\(option.title): match the window", isOn: follows).labelsHidden()
            } label: {
                SettingsLabel("\(option.title): match the window", help: help)
            }
            NumberRow(name: option.title, value: points, range: 0 ... 40, step: 1, unit: "pt")
                .disabled(follows.wrappedValue)
        }
    }
}
