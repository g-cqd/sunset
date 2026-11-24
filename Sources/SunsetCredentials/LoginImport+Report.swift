/// What the person is told of a file read, before it is kept and after.
extension LoginImport {
    /// The program the file seems to come from, as the person knows it.
    public var sourceName: String {
        switch source {
            case .applePasswords: "Apple Passwords"
            case .chrome: "Chrome, Edge or Brave"
            case .firefox: "Firefox"
            case .bitwarden: "Bitwarden"
            case .onePassword: "1Password"
            case .lastPass: "LastPass"
            case .generic: "a CSV file"
        }
    }

    /// One line for each thing there is to say, in the order of importance; a line only when there is something.
    public var report: [String] {
        var lines = [Self.count(entries.count, "login")]
        if duplicates > 0 { lines.append("\(duplicates) already in the vault or earlier in the file") }
        let empty = skipped.count { $0.reason == .empty }
        if !skipped.isEmpty {
            let others = skipped.count - empty
            var parts = ["\(others) notes, cards or archived items"]
            if empty > 0 { parts.append("\(empty) empty") }
            if others == 0 { parts = ["\(empty) empty"] }
            lines.append("\(skipped.count) rows are not logins (" + parts.joined(separator: ", ") + ")")
        }
        if !warnings.isEmpty {
            lines.append("\(Self.count(warnings.count, "one-time code")) could not be read and was left out")
        }
        return lines
    }

    private static func count(_ number: Int, _ noun: String) -> String {
        "\(number) \(noun)\(number == 1 ? "" : "s")"
    }
}
