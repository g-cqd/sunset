/// What the install prompt says an extension may do (roadmap 0109 C, ADR-0109: granted at install, all or nothing): its sites
/// first, every website above the rest, then what its permissions let it do, each once, in plain words. Permissions that let it
/// do nothing the person must weigh (its own storage, alarms) are not listed.
package enum ExtensionWording {
    package static func lines(permissions: [String], sites: [String]) -> [String] {
        var seen = Set<String>()
        let said = sites.map(site)
        let siteLines = said.filter { $0 == everySite } + said.filter { $0 != everySite }
        let permissionLines = permissions.compactMap(permission).sorted()
        return (siteLines + permissionLines).filter { seen.insert($0).inserted }
    }

    static let everySite = "Read and change every website"

    package static func site(_ pattern: String) -> String {
        if pattern == "<all_urls>" { return everySite }
        let host = pattern.split(separator: "/").dropFirst(1).first.map(String.init) ?? pattern
        if host == "*" { return everySite }
        if host.hasPrefix("*.") { return "Read and change pages on \(host.dropFirst(2)) and its subdomains" }
        return "Read and change pages on \(host)"
    }

    package static func permission(_ name: String) -> String? {
        switch name {
            case "storage", "unlimitedStorage", "alarms", "contextMenus", "menus", "activeTab", "scripting": nil
            case "tabs": "See your open tabs' titles and addresses"
            case "cookies": "Read and change cookies"
            case "history": "Read and change your browsing history"
            case "bookmarks": "Read and change your bookmarks"
            case "downloads": "Manage your downloads"
            case "notifications": "Show notifications"
            case "clipboardWrite": "Copy to the clipboard"
            case "clipboardRead": "Read the clipboard"
            case "webNavigation": "See which pages you open"
            case "declarativeNetRequest", "declarativeNetRequestWithHostAccess", "declarativeNetRequestFeedback":
                "Block or change requests pages make"
            case "nativeMessaging": "Talk to an app on this Mac"
            case "geolocation": "Know where you are"
            default: "Use “\(name)”"
        }
    }
}
