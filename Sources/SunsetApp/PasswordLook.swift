import SunsetCredentials

/// How an entry is named and pictured, in the Library's list and on its page.
enum PasswordLook {
    static func template(_ entry: VaultEntry) -> EntryTemplate? {
        EntryTemplate.shipped.first { $0.id == entry.template }
    }

    static func symbol(_ entry: VaultEntry) -> String {
        template(entry)?.symbol ?? "lock"
    }

    static func title(_ entry: VaultEntry) -> String {
        entry.title.isEmpty ? "Untitled" : entry.title
    }

    /// What an untitled entry's title field suggests: "New Card".
    static func prompt(_ entry: VaultEntry) -> String {
        "New " + (template(entry)?.name ?? "Entry")
    }

    /// A login's username, else its template's name.
    static func subtitle(_ entry: VaultEntry) -> String {
        guard let user = entry.field(named: "Username")?.value, !user.isEmpty else {
            return template(entry)?.name ?? "Entry"
        }
        return user
    }
}
