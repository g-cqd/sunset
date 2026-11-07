/// Where the configuration file lives.
public enum ConfigurationLocation {
    /// `$SUNSET_CONFIG` if set (the file itself), else `$XDG_CONFIG_HOME/sunset/config.json`, else `~/.config/sunset/config.json`. Empty variables count as unset.
    public static func path(environment: [String: String], home: String) -> String {
        func trimmed(_ path: String) -> String {
            var result = path
            while result.count > 1, result.hasSuffix("/") { result.removeLast() }
            return result
        }
        if let file = environment["SUNSET_CONFIG"], !file.isEmpty { return file }
        if let base = environment["XDG_CONFIG_HOME"], !base.isEmpty { return trimmed(base) + "/sunset/config.json" }
        return trimmed(home) + "/.config/sunset/config.json"
    }

    /// Where the theme `name` is: `themes/<name>.json` in the directory of the configuration file.
    public static func themePath(named name: String, besideConfig config: String) -> String {
        var directory = config
        if let slash = directory.lastIndex(of: "/") { directory = String(directory[..<slash]) } else { directory = "." }
        return directory + "/themes/" + name + ".json"
    }
}
