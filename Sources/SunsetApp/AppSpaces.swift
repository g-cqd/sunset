import Foundation
import SunsetConfig
import SunsetPane
import SunsetRuntime
import SunsetShell

/// The Spaces of the app (R4; ADR-0045, ADR-0047). Every window that lists tabs (the sidebar, the built-in bar) shows one
/// of them; a Space keeps its tabs when its last window closes, unless the settings say otherwise. A private window, and a
/// window that is one tab (the system's tab bar, a window each), has a Space of its own instead.
@MainActor enum AppSpaces {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    static var runtime = Runtime.live

    static let all: SpacesModel = {
        let spaces = SpacesModel(
            first: SpaceModel(favorites: AppFavorites.shared, keepsTabs: true),
            ownership: ownership,
            makeFavorites: AppFavorites.make
        )
        spaces.onChange = { SessionStore.shared.scheduleSave() }
        spaces.profiles.onChange = { SessionStore.shared.scheduleSave() }
        return spaces
    }()

    /// Whose the Favorites and the Pinned grid are (`spaces.favorites`, `spaces.pinned`; roadmap 0044): read once, when the
    /// Spaces are made; a change takes effect the next time Sunset opens.
    static let ownership: SpacesSession.Ownership = {
        let scopes = AppConfiguration.shared.configuration.spaces
        return SpacesSession.Ownership(favoritesBySpace: scopes.favorites == .space, pinnedByApp: scopes.pinned == .app)
    }()

    /// Every set of kept entries: each profile's grid and Favorites, and each Space's own Favorites; each once.
    static var kept: [FavoritesModel] {
        var each: [FavoritesModel] = []
        let lists = all.profiles.profiles.flatMap { [$0.pinned, $0.favorites] } + all.spaces.map(\.favorites)
        for list in lists where !each.contains(where: { $0 === list }) { each.append(list) }
        return each
    }

    /// The first Space: the one there was before there were several.
    static var shared: SpaceModel {
        all.spaces[0]
    }

    private static var cleaner: Task<Void, Never>?

    /// The tabs left by the last window are closed once they have waited as long as `tabs.closeStoppedAfter` says: now, when
    /// they already have (at launch), else when the time comes, if Sunset is still running and no window showed them.
    static func cleanStopped() {
        cleaner?.cancel()
        let seconds = AppConfiguration.shared.configuration.tabs.closeStoppedAfter * 3600
        guard seconds > 0 else { return }
        var closed = false
        for space in all.spaces where space.closeStopped(after: seconds) { closed = true }
        if closed { SessionStore.shared.scheduleSave() }
        guard let soonest = all.spaces.compactMap(\.stopped).min() else { return }
        let left = max(seconds - runtime.now().timeIntervalSince(soonest), 1)
        cleaner = runtime.task {
            await runtime.sleep(for: .seconds(left))
            guard !Task.isCancelled else { return }
            cleanStopped()
        }
    }
}
