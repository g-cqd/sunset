import SunsetConfig
import SunsetPane
import SunsetShell
import SwiftUI

/// What one profile keeps between runs (ADR-0081), under its row in Settings › Web › Profiles: each choice the app's
/// (Privacy and security › Browsing) or the profile's own.
struct ProfileKeepRows: View {
    let profile: ProfileModel
    let profiles: ProfilesModel
    @State private var open = false
    private let config = AppConfiguration.shared

    var body: some View {
        DisclosureGroup(isExpanded: $open) {
            FoldContent {
                row(
                    "Sites' data",
                    \.siteData,
                    Configuration.Web.Keep.SiteData.allCases.map(\.rawValue),
                    app: app.siteData.rawValue
                )
                row("Cache", \.cache, Configuration.Web.Keep.Choice.allCases.map(\.rawValue), app: app.cache.rawValue)
                row(
                    "Traces of visits",
                    \.traces,
                    Configuration.Web.Keep.Choice.allCases.map(\.rawValue),
                    app: app.traces.rawValue
                )
            }
        } label: {
            Text("Between runs: \(Self.summary(profile.profile.keep))").foregroundStyle(.secondary)
        }
    }

    private var app: Configuration.Web.Keep { config.configuration.web.keep }

    /// "as in Settings", or how many of its own.
    static func summary(_ keep: Profile.Keep) -> String {
        let own = [keep.cache, keep.traces, keep.siteData].compactMap(\.self).count
        return own == 0 ? "as in Settings" : own == 1 ? "1 choice of its own" : "\(own) choices of its own"
    }

    static func title(_ value: String) -> String {
        switch value {
            case "keep": "Kept"
            case "keepChosen": "Kept for the sites chosen"
            case "clearOnQuit": "Cleared on quit"
            default: value
        }
    }

    private func row(_ title: String, _ path: WritableKeyPath<Profile.Keep, String?>, _ values: [String], app: String)
        -> some View
    {
        LabeledContent {
            Picker(
                title,
                selection: Binding(
                    get: { profile.profile.keep[keyPath: path] ?? "" },
                    set: { value in
                        var keep = profile.profile.keep
                        keep[keyPath: path] = value.isEmpty ? nil : value
                        profiles.setKeep(keep, for: profile)
                    }
                )
            ) {
                Text("As in Settings (\(Self.title(app)))").tag("")
                ForEach(values, id: \.self) { Text(Self.title($0)).tag($0) }
            }
            .labelsHidden()
            .fixedSize()
        } label: {
            SettingsLabel(title)
        }
    }
}
