import SunsetConfig
import SunsetPane
import SunsetShell
import SwiftUI

/// The profile a new window opens on (`tabs.startProfile`), chosen among the profiles (n117: it was a name typed); a name
/// the file holds that no profile has any more is shown as it is, not lost.
struct StartProfilePicker: View {
    let title: String
    let config: any SettingsStore

    private var names: [String] {
        AppSpaces.all.profiles.profiles.map(\.profile.name)
    }

    var body: some View {
        let named = config.configuration.tabs.startProfile
        LabeledContent {
            Picker(title, selection: config.binding(\.tabs.startProfile)) {
                Text("Default").tag("")
                ForEach(names, id: \.self) { Text($0).tag($0) }
                if !named.isEmpty, !names.contains(named) { Text(named).tag(named) }
            }
            .labelsHidden()
            .fixedSize()
        } label: {
            SettingsLabel(title)
        }
    }
}
