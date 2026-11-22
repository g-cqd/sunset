import AppKit
import SunsetAppCore
import SunsetConfig
import SunsetPane
import SunsetShell

/// The scopes of the app that are on, from `features` in the configuration, and what turning one off does to what is
/// open: its panes close in every Space and every window, and what is kept of it is unloaded.
@MainActor enum AppScopes {
    /// The scopes as the configuration says.
    static var current: Scopes {
        let features = AppConfiguration.shared.configuration.features
        return Scopes(
            terminal: features.terminal,
            web: features.web,
            documents: features.documents,
            passwords: features.credentials
        )
    }

    /// Every Space there is: the app's, and, once there are windows, those of windows that have their own (private, one
    /// tab a window). Before the application object exists (the session is read in `App.init`) there is no window to ask.
    private static var spaces: [SpaceModel] {
        var all = AppSpaces.all.spaces
        guard NSApp != nil else { return all }
        for (_, tabs) in TabRegistry.shared.allWindows() where !all.contains(where: { $0 === tabs.space }) {
            all.append(tabs.space)
        }
        return all
    }

    /// Everything that keeps entries: each profile's Pinned grid and Favorites, each Space's own Favorites.
    private static var kept: [FavoritesModel] {
        AppSpaces.kept
    }

    /// How many tabs and open kept entries have a pane of the scope.
    static func openCount(of scope: Scopes.Scope) -> Int {
        spaces.reduce(0) { $0 + $1.count(of: scope) } + kept.reduce(0) { $0 + $1.openCount(of: scope) }
    }

    /// What the question says before a scope is turned off with things open.
    static func sentence(closing scope: Scopes.Scope) -> String {
        ScopeClosing.sentence(scope, open: openCount(of: scope))
    }

    /// Closes and unloads everything of the scopes that are off, and tells every window. Called when the configuration
    /// changes and when a session is read: nothing of a scope that is off is left running.
    static func enforce() {
        let scopes = current
        // Turned off, the vault locks: nothing of it stays open in memory.
        if !scopes.passwords { AppPasswords.model.lock() }
        for scope in scopes.off where scope.isTabs {
            for space in spaces { space.close(scope) }
            for favorites in kept { favorites.unload(scope) }
        }
        guard NSApp != nil else { return }
        for (_, tabs) in TabRegistry.shared.allWindows() { tabs.scopes = scopes }
    }

    /// Hands files to the app that opens each by default; one whose default app is Sunset itself (it would come straight
    /// back) is shown in the Finder instead.
    static func openElsewhere(_ paths: [String]) {
        var shown: [URL] = []
        for url in paths.map({ URL(fileURLWithPath: $0) }) {
            let handler = NSWorkspace.shared.urlForApplication(toOpen: url)
            if let handler, handler.standardizedFileURL != Bundle.main.bundleURL.standardizedFileURL {
                NSWorkspace.shared.open(url)
            } else {
                shown.append(url)
            }
        }
        if !shown.isEmpty { NSWorkspace.shared.activateFileViewerSelecting(shown) }
    }
}
