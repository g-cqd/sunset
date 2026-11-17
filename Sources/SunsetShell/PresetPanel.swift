import SunsetPane
import SwiftUI

/// The fourth light's panel (t287): the five presets, each drawn as its shape, those the tabs cannot fill disabled.
struct PresetPanel: View {
    let tabs: TabsModel
    let done: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            Text("Lay Out the Tab").font(Design.Text.detail.weight(.semibold)).foregroundStyle(.secondary)
            HStack(spacing: Design.Space.m) {
                ForEach(SplitPreset.allCases, id: \.self) { preset in
                    Button {
                        tabs.apply(preset)
                        done()
                    } label: {
                        PresetShape(preset: preset)
                    }
                    .buttonStyle(.plain)
                    .disabled(!tabs.canApply(preset))
                    .help(preset.title)
                    .accessibilityLabel(preset.title)
                }
            }
        }
        .padding(Design.Space.l)
    }
}
