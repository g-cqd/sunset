import Foundation

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
        var lines = [kinds]
        if duplicates > 0 { lines.append("\(duplicates) already in the vault or earlier in the file") }
        if !skipped.isEmpty {
            let parts = SkipReason.inReportOrder.compactMap { reason -> String? in
                let number = skipped.count { $0.reason == reason }
                return number == 0 ? nil : "\(number) \(reason.words)"
            }
            lines.append(
                "\(skipped.count) \(skipped.count == 1 ? "row is" : "rows are") not imported ("
                    + parts.joined(separator: ", ") + ")"
            )
        }
        let codes = warnings.count { $0.reason == .unreadableCode }
        if codes > 0 { lines.append("\(Self.count(codes, "one-time code")) could not be read and was left out") }
        let expiries = warnings.count { $0.reason == .unreadableExpiry }
        if expiries > 0 {
            lines.append("\(expiries) card \(expiries == 1 ? "expiry" : "expiries") could not be read and was left out")
        }
        return lines
    }

    /// "2 logins, 1 card": the entries by kind, in the order of what people keep most.
    private var kinds: String {
        let kept: [(UUID?, String, String)] = [
            (EntryTemplate.login.id, "login", "logins"), (EntryTemplate.secureNote.id, "secure note", "secure notes"),
            (EntryTemplate.card.id, "card", "cards"), (EntryTemplate.identity.id, "identity", "identities")
        ]
        var parts = kept.compactMap { id, one, many -> String? in
            let number = entries.count { $0.template == id }
            return number == 0 ? nil : "\(number) \(number == 1 ? one : many)"
        }
        let other = entries.count { entry in !kept.contains { $0.0 == entry.template } }
        if other > 0 { parts.append("\(other) other \(other == 1 ? "entry" : "entries")") }
        return parts.isEmpty ? "0 logins" : parts.joined(separator: ", ")
    }

    private static func count(_ number: Int, _ noun: String) -> String {
        "\(number) \(noun)\(number == 1 ? "" : "s")"
    }
}
