import SunsetStorage

/// The vault's logins written as CSV for another program (roadmap 0095 D, out): Apple Passwords' columns, which the importers of the
/// others take. The cells are as they are kept, an apostrophe never put in front of what begins like a formula: the file is for a program
/// that reads it back, and a password is not to change on the way (a spreadsheet must not open it, which the person is told). Only logins:
/// a card's concealed fields are not passwords.
public enum LoginExport {
    public struct Result: Equatable, Sendable {
        public let text: String
        public let exported: Int
        /// Entries that are not logins (cards, notes, the person's own templates).
        public let skipped: Int
    }

    public static let header = ["Title", "URL", "Username", "Password", "Notes", "OTPAuth"]

    public static func csv(of entries: [VaultEntry]) -> Result {
        var text = CSV.line(header, formulas: .keep)
        var exported = 0
        for entry in entries {
            guard entry.template == EntryTemplate.login.id, let credentials = LoginMatch.credentials(of: entry) else {
                continue
            }
            let code =
                entry.field(named: "One-Time Code")?.value
                ?? entry.sections.flatMap(\.fields).first { $0.kind == .oneTimeCode }?.value
            let website = entry.field(named: "Website")?.value ?? ""
            text += CSV.line(
                [entry.title, website, credentials.username, credentials.password, entry.note, code ?? ""],
                formulas: .keep
            )
            exported += 1
        }
        return Result(text: text, exported: exported, skipped: entries.count - exported)
    }
}
