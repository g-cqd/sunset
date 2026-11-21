import SunsetConfig
import SunsetShell
import SwiftUI

/// The welcome's security question (roadmap 0111 H): a model for the settings that weigh safety against pages working.
struct WelcomeSecurity: View {
    let store: AppConfiguration

    private var choice: Binding<SecurityPreset?> {
        Binding(
            get: { SecurityPreset.matching(store.configuration.web) },
            set: { preset in if let preset { store.update { preset.apply(to: &$0.web) } } }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Welcome.row) {
            Picker("Model", selection: choice) {
                ForEach(SecurityPreset.allCases, id: \.self) { preset in
                    WelcomeOption(title: preset.title, detail: preset.summary)
                        .padding(.bottom, Design.Space.m)
                        .tag(Optional(preset))
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
            if choice.wrappedValue == nil {
                Text("Your settings were changed by hand; choosing a model sets them again.").font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
