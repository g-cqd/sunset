import Foundation
import SunsetConfig
import SunsetWeb

/// The app's one history (web step e): the file beside the session, opened once; pages older than `web.historyKeep` are forgotten at launch.
@MainActor enum AppHistory {
    static let shared: HistoryStore? = {
        let path = SessionLocation.historyPath(
            environment: ProcessInfo.processInfo.environment,
            home: NSHomeDirectory()
        )
        let store = HistoryStore(path: path)
        if let seconds = AppConfiguration.shared.configuration.web.historyKeep.seconds {
            store?.expire(before: Date().addingTimeInterval(-seconds))
        }
        store?.onChange = { HistoryChanges.shared.bump() }
        return store
    }()
}
