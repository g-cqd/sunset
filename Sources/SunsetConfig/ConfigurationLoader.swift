/// Reads a configuration file together with the theme it names: the defaults, then the theme, then the file's own keys.
public enum ConfigurationLoader {
    public struct Result: Sendable, Equatable {
        public var configuration: Configuration
        public var issues: [ConfigurationIssue]
    }

    /// `readTheme` returns the text of the theme with a name, or nil when there is none. Problems with the theme are issues, not errors: the file is still used.
    public static func load(
        _ text: String,
        readTheme: (String) -> String?
    ) throws(ConfigurationError) -> Result {
        let plain = try ConfigurationParser.parse(text)
        guard let name = plain.configuration.theme else {
            return Result(configuration: plain.configuration, issues: plain.issues)
        }
        var themeIssues: [ConfigurationIssue] = []
        var base = Configuration()
        if !isSafeThemeName(name) {
            themeIssues.append(
                ConfigurationIssue(
                    path: "theme",
                    message: "\"\(name)\" is not a valid theme name (letters, digits, - and _)"
                )
            )
        } else if let themeText = readTheme(name) {
            do {
                let theme = try ConfigurationParser.parse(themeText, scope: .theme)
                base = theme.configuration
                themeIssues += theme.issues.map { ConfigurationIssue(path: "theme:" + $0.path, message: $0.message) }
            } catch {
                themeIssues.append(
                    ConfigurationIssue(path: "theme", message: "the theme \"\(name)\" is not valid: \(describe(error))")
                )
            }
        } else {
            themeIssues.append(ConfigurationIssue(path: "theme", message: "there is no theme named \"\(name)\""))
        }
        let merged = try ConfigurationParser.parse(text, base: base)
        return Result(configuration: merged.configuration, issues: themeIssues + merged.issues)
    }

    /// A theme name is a file name: no directories, no leading dot.
    public static func isSafeThemeName(_ name: String) -> Bool {
        guard !name.isEmpty, name.count <= 64, !name.hasPrefix(".") else { return false }
        return name.unicodeScalars.allSatisfy { scalar in
            ("a" ... "z").contains(scalar) || ("A" ... "Z").contains(scalar) || ("0" ... "9").contains(scalar)
                || scalar == "-"
                || scalar == "_"
        }
    }

    private static func describe(_ error: ConfigurationError) -> String {
        switch error {
            case .syntax(let message, let offset): offset.map { "\(message) (byte \($0))" } ?? message
            case .notAnObject: "the file must contain an object"
        }
    }
}
