import SunsetConfig
import SunsetPane
import SunsetShell
import SwiftUI

/// At the top of Settings, with more than one profile: whose settings are shown, all profiles' or one profile's own.
/// With a profile chosen, only what a profile can set is listed.
struct ScopeRow: View {
    @Bindable var content: SettingsContent

    var body: some View {
        let profiles = AppSpaces.all.profiles.profiles
        if profiles.count > 1 {
            Section {
                LabeledContent {
                    Picker("Settings for", selection: $content.scope) {
                        Text("All profiles").tag(UUID?.none)
                        Divider()
                        ForEach(profiles, id: \.profile.id) { model in
                            Text(model.profile.name.isEmpty ? "Profile" : model.profile.name)
                                .tag(UUID?.some(model.profile.id))
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                } label: {
                    SettingsLabel("Settings for")
                    if content.scope != nil {
                        Text("Only what a profile can set otherwise. What it does not set follows all profiles.")
                    }
                }
            }
        }
    }
}
