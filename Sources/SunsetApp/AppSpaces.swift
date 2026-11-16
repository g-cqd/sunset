import Foundation
import SunsetConfig
import SunsetShell

/// The Space of the app (R4; ADR-0045): the one there is until Spaces can be made (roadmap 0021, S-c). Every window that
/// lists tabs (the sidebar, the built-in bar) is a view of it; it keeps its tabs when its last window closes, unless the
/// settings say otherwise. A private window, and a window that is one tab (the system's tab bar, a window each), has a
/// Space of its own instead.
@MainActor enum AppSpaces {
    static let shared = SpaceModel(favorites: AppFavorites.shared, keepsTabs: true)

    private static var cleaner: Task<Void, Never>?

    /// The tabs left by the last window are closed once they have waited as long as `tabs.closeStoppedAfter` says: now, when
    /// they already have (at launch), else when the time comes, if Sunset is still running and no window showed them.
    static func cleanStopped() {
        cleaner?.cancel()
        let seconds = AppConfiguration.shared.configuration.tabs.closeStoppedAfter * 3600
        guard seconds > 0, let since = shared.stopped else { return }
        if shared.closeStopped(after: seconds) {
            SessionStore.shared.scheduleSave()
            return
        }
        let left = max(seconds - Date().timeIntervalSince(since), 1)
        cleaner = Task {
            try? await Task.sleep(for: .seconds(left))
            guard !Task.isCancelled else { return }
            cleanStopped()
        }
    }
}
