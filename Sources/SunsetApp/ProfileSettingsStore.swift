import SunsetConfig
import SunsetPane
import SunsetShell

/// One profile's settings, for Settings with that profile chosen (roadmap 0050; the owner's notes n1, n38): read as all
/// profiles' with the profile's own values over them; written as only what then differs from all profiles, kept with the
/// profile in the session. Pages opened from then on use them; open pages keep theirs until reloaded.
@MainActor final class ProfileSettingsStore: SettingsStore {
    let profile: ProfileModel
    let profiles: ProfilesModel

    init(profile: ProfileModel, profiles: ProfilesModel) {
        self.profile = profile
        self.profiles = profiles
    }

    var configuration: Configuration {
        ProfileOverrides.apply(profile.profile.overrides, to: AppConfiguration.shared.configuration)
    }

    func update(_ edit: (inout Configuration) -> Void) {
        var changed = configuration
        edit(&changed)
        let overrides = ProfileOverrides.diff(profile: changed, app: AppConfiguration.shared.configuration)
        profiles.setOverrides(overrides, for: profile)
        // Its store's proxy now.
        AppBlocking.apply(AppConfiguration.shared.configuration.web)
    }

    /// Whether `option` is set otherwise in this profile: every key it writes that a profile may set differs.
    func isOwn(_ option: SettingsOption) -> Bool { option.keys.contains { profile.profile.overrides[$0] != nil } }

    /// `option` follows all profiles again.
    func reset(_ option: SettingsOption) {
        var overrides = profile.profile.overrides
        for key in option.keys { overrides[key] = nil }
        profiles.setOverrides(overrides, for: profile)
        AppBlocking.apply(AppConfiguration.shared.configuration.web)
    }
}
