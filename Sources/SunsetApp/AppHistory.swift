import Foundation
import SunsetAppCore
import SunsetConfig
import SunsetRuntime
import SunsetStorage
import SunsetWeb

/// The app's one history (web step e): sealed records of the state database (R12 step ST-3), read once; pages older than
/// `web.historyKeep` are forgotten at launch. The file of before the database is taken in once, then removed.
@MainActor enum AppHistory {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    static var runtime = Runtime.live

    static let shared: HistoryStore? = {
        let storage = SunsetStore.shared
        let table = storage.table("history")
        let store = HistoryStore(table: table)
        if let table {
            // Once the kept history is in memory (a long one is read off the main actor), so that nothing is taken in twice.
            runtime.task { @MainActor in
                await store.ready()
                if store.importLegacy(at: storage.places.legacyHistory) != nil {
                    storage.retire(storage.places.legacyHistory, when: table.count() >= store.count)
                }
            }
        }
        if let seconds = AppConfiguration.shared.configuration.web.historyKeep.seconds {
            store.expire(before: runtime.now().addingTimeInterval(-seconds))
        }
        store.onChange = { HistoryChanges.shared.bump() }
        return store
    }()
}
