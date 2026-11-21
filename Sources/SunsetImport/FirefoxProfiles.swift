import Foundation

/// The profiles Firefox lists in its `profiles.ini` (roadmap 0111 D).
public enum FirefoxProfiles {
    /// Each `[ProfileN]` section: its folder (`Path`, under Firefox's own when `IsRelative=1`) and its name (the folder's
    /// last part when it has none); the one an `[Install…]` section names as its default first, then the file's order.
    public static func read(_ text: String) -> [BrowserProfile] {
        var profiles: [BrowserProfile] = []
        var installDefault: String?
        for (name, values) in sections(text) {
            if name.hasPrefix("Install"), let path = values["Default"] { installDefault = installDefault ?? path }
            guard name.hasPrefix("Profile"), let path = values["Path"], !path.isEmpty else { continue }
            let given = values["Name"]?.trimmingCharacters(in: .whitespaces) ?? ""
            let last = path.split(separator: "/").last.map(String.init) ?? path
            profiles.append(BrowserProfile(folder: path, name: given.isEmpty ? last : given))
        }
        if let first = profiles.firstIndex(where: { $0.folder == installDefault }) {
            profiles.insert(profiles.remove(at: first), at: 0)
        }
        return profiles
    }

    /// The sections of an INI file in order, each with its `key=value` lines.
    static func sections(_ text: String) -> [(name: String, values: [String: String])] {
        var result: [(name: String, values: [String: String])] = []
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("["), line.hasSuffix("]") {
                result.append((String(line.dropFirst().dropLast()), [:]))
            } else if let equals = line.firstIndex(of: "="), !result.isEmpty {
                result[result.count - 1].values[String(line[..<equals])] = String(line[line.index(after: equals)...])
            }
        }
        return result
    }
}
