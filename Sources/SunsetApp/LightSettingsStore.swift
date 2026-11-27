import Foundation
import SunsetConfig

/// Settings in the light scheme for one setting (design 0009): what it shows is the configuration as it is in light; an
/// edit is kept as that setting's light value (`lightValues`), its own value left as it is.
@MainActor final class LightSettingsStore: SettingsStore {
    let base: any SettingsStore
    let key: String

    init(base: any SettingsStore, key: String) {
        self.base = base
        self.key = key
    }

    var configuration: Configuration {
        base.configuration.inLight()
    }

    var profileID: UUID? {
        base.profileID
    }

    func update(_ edit: (inout Configuration) -> Void) {
        var light = configuration
        edit(&light)
        guard let literal = Configuration.literal(of: key, in: light) else { return }
        base.update { $0.lightValues[key] = literal }
    }
}
