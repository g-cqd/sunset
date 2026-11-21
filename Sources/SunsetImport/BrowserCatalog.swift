import Foundation

/// The browsers Sunset knows how to import from (roadmap 0111 G); the "any other browser" path is an exported file.
public enum BrowserCatalog {
    private static let support = "Library/Application Support/"

    /// One browser a line, in the order shown: its kind, its name, its folder (under Application Support unless it
    /// starts with `~/`).
    private static let table = """
        safari   | Safari               | ~/Library/Safari
        chromium | Google Chrome        | Google/Chrome
        chromium | Google Chrome Beta   | Google/Chrome Beta
        chromium | Google Chrome Canary | Google/Chrome Canary
        chromium | Arc                  | Arc/User Data
        chromium | Brave                | BraveSoftware/Brave-Browser
        chromium | Microsoft Edge       | Microsoft Edge
        chromium | Vivaldi              | Vivaldi
        chromium | Opera                | com.operasoftware.Opera
        chromium | Chromium             | Chromium
        firefox  | Firefox              | Firefox
        firefox  | Zen                  | zen
        firefox  | LibreWolf            | librewolf
        firefox  | Waterfox             | Waterfox
        """

    public static let known: [Browser] = table.split(separator: "\n")
        .compactMap { line in
            let fields = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            let kinds: [String: BrowserKind] = ["safari": .safari, "chromium": .chromium, "firefox": .firefox]
            guard fields.count == 3, let kind = kinds[fields[0]] else { return nil }
            let folder = fields[2].hasPrefix("~/") ? String(fields[2].dropFirst(2)) : support + fields[2]
            return Browser(name: fields[1], kind: kind, folder: folder)
        }

    /// The known browsers whose folder exists under `home`, in the catalogue's order.
    public static func installed(home: String, exists: (String) -> Bool) -> [Browser] {
        known.filter { exists(path(of: $0, home: home)) }
    }

    /// The browser's folder under `home`.
    public static func path(of browser: Browser, home: String) -> String {
        (home.hasSuffix("/") ? home : home + "/") + browser.folder
    }
}
