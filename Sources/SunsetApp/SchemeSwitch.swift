import SunsetConfig
import SunsetMetrics
import SunsetShell
import SwiftUI

/// Above the look settings (design 0009): which scheme they show (the system's values, read only, or Sunset's in light or
/// in dark), a preview of it, and copying or resetting a whole scheme.
struct SchemeSwitch: View {
    @Bindable var content: SettingsContent
    let config: any SettingsStore
    let editing: SchemeEditing
    let light: Bool
    let layout: LayoutMetrics

    private static let note =
        "System shows macOS's values. A change in Light or Dark is that scheme's only; the other keeps the system's."

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            HStack {
                Picker("Scheme", selection: selection) {
                    ForEach(SchemeEditing.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                Spacer()
                actions
            }
            SchemePreview(look: look, light: light, layout: layout)
            Text(Self.note).font(Design.Text.detail).foregroundStyle(.secondary)
        }
    }

    private var selection: Binding<SchemeEditing> {
        Binding(get: { editing }, set: { content.editing = $0 })
    }

    /// The configuration as the switch shows it.
    private var look: Configuration {
        switch editing {
            case .system: config.configuration.withNativeLooks(light: light)
            case .light: config.configuration.inLight()
            case .dark: config.configuration
        }
    }

    private var actions: some View {
        Menu {
            Button("Copy Dark to Light") { config.update { $0.copyLooks(toLight: true) } }
            Button("Copy Light to Dark") { config.update { $0.copyLooks(toLight: false) } }
            Divider()
            Button("Use the System's in Light") { config.update { $0.resetLooks(light: true) } }
            Button("Use the System's in Dark") { config.update { $0.resetLooks(light: false) } }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuStyle(.button)
        .buttonStyle(.borderless)
        .fixedSize()
        .accessibilityLabel("Light and dark")
    }
}
