import SunsetConfig
import SunsetPane
import SunsetShell
import SwiftUI

/// Under a setting the profile chosen sets otherwise: it says so, and lets it follow all profiles again.
struct OwnSettingRow: View {
    let store: ProfileSettingsStore
    let option: SettingsOption

    var body: some View {
        LabeledContent {
            Button("Use All Profiles\u{2019} Setting") { store.reset(option) }
        } label: {
            Text("Set for \(store.profile.profile.name)").font(Design.Text.detail).foregroundStyle(.secondary)
        }
    }
}
