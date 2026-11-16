import SunsetShell

/// The Space of the app (R4; ADR-0045): the one there is until Spaces can be made (roadmap 0021, S-c). Every window that
/// lists tabs (the sidebar, the built-in bar) is a view of it; it keeps its tabs when its last window closes. A private
/// window, and a window that is one tab (the system's tab bar, a window each), has a Space of its own instead.
@MainActor enum AppSpaces {
    static let shared = SpaceModel(favorites: AppFavorites.shared, keepsTabs: true)
}
