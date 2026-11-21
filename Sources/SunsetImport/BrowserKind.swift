/// How a browser keeps what is imported from it.
public enum BrowserKind: Sendable, Equatable {
    /// Chromium's: a folder of profiles listed in `Local State`, each with `Bookmarks` and `Extensions`.
    case chromium
    /// Firefox's: `profiles.ini`, each profile with `places.sqlite`, `containers.json`, `extensions.json`.
    case firefox
    /// Safari's: one `Bookmarks.plist`, behind Full Disk Access.
    case safari
}
