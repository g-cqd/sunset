import SunsetAppCore
import SunsetConfig
import SunsetStorage

extension SunsetStore {
    /// The app's: the places of this run, its problems said in the window, the setting read from the configuration.
    @MainActor static let shared = SunsetStore(places: .current, problems: .shared) {
        AppConfiguration.shared.configuration.storage.importedFiles == .trash
    }
}
