import Foundation
import SunsetConfig

/// Settings in a scheme for the look settings (design 0009): macOS's values in a scheme, read only (Settings' System), or
/// the light scheme for one setting, where what it shows is the configuration as it is in light and an edit is kept as
/// that setting's light value (`lightValues`; none when it is macOS's), its own value left as it is.
@MainActor final class LightSettingsStore: SettingsStore {
    enum Values {
        /// macOS's, in light or in dark.
        case native(light: Bool)
        /// The light ones; edits go to the light value of `key`.
        case light(key: String)
    }

    let base: any SettingsStore
    let values: Values

    init(base: any SettingsStore, _ values: Values) {
        self.base = base
        self.values = values
    }

    var configuration: Configuration {
        switch values {
            case .native(let light): base.configuration.withNativeLooks(light: light)
            case .light: base.configuration.inLight()
        }
    }

    var profileID: UUID? {
        base.profileID
    }

    func update(_ edit: (inout Configuration) -> Void) {
        guard case .light(let key) = values else { return }
        var light = configuration
        edit(&light)
        guard let literal = Configuration.literal(of: key, in: light) else { return }
        base.update { $0.setLight(key, literal) }
    }
}
