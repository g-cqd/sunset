extension ExtensionStoreLink {
    /// The browser an extension store's site is shown, whatever the default or a site's rule (the owner, 2026-11-21: installing
    /// from the stores "should always be possible"): each store offers its install only to the browser it serves; nil
    /// elsewhere.
    package static func storeAgent(forHost host: String?) -> BrowserAgent? {
        switch host?.lowercased() {
            case "chromewebstore.google.com", "chrome.google.com": .chrome
            case "addons.mozilla.org": .firefox
            default: nil
        }
    }
}
