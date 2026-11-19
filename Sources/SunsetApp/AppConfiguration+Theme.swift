import SunsetConfig
import SunsetHost
import SunsetRuntime

/// The theme in force, watched as the configuration file is.
extension AppConfiguration {
    /// Watches the file of the theme in force too: editing a theme changes the windows as editing the configuration does.
    func watchTheme(_ name: String?) {
        guard name != watchedTheme else { return }
        watchedTheme = name
        themeWatcher?.stop()
        themeWatching?.cancel()
        themeWatcher = nil
        guard let name, ConfigurationLoader.isSafeThemeName(name) else { return }
        let watcher = FileWatcher(path: ConfigurationLocation.themePath(named: name, besideConfig: path))
        themeWatcher = watcher
        watcher.start()
        themeWatching = runtime.task(role: .observation) { [weak self] in
            for await _ in watcher.changes { self?.reloadForTheme() }
        }
    }

    /// The theme's file changed: read the configuration again (it is the same text, so the guard against our own writes is bypassed).
    func reloadForTheme() {
        lastWritten = nil
        reload()
    }
}
