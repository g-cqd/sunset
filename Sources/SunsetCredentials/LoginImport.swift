import Foundation

/// Logins read from a CSV file that a browser or a password manager exported (roadmap 0095 D): a login entry for each row that is one,
/// the rows that are not said and counted, and a way to leave out what the vault holds already. The file is in the clear by nature: what
/// it holds is the person's to delete, and nothing here keeps it.
public struct LoginImport: Equatable, Sendable {
    public enum Source: String, Equatable, Sendable {
        case applePasswords, chrome, firefox, bitwarden, onePassword, lastPass, aegis, twoFAS, andOTP, generic
    }

    public enum SkipReason: Equatable, Sendable {
        /// No password and no username.
        case empty
        /// An identity or another item of a manager's CSV export that is neither a login, a note nor a card.
        case notALogin
        /// An archived item.
        case archived
        /// In the manager's trash.
        case deleted
        /// A kind of item this version of Sunset does not know.
        case unknownKind
    }

    public enum WarningReason: Equatable, Sendable {
        /// The login is kept, its one-time code is not: what the file has is neither an `otpauth://` link nor a secret.
        case unreadableCode
        /// A card is kept, its expiry is not: the month or the year is not one.
        case unreadableExpiry
    }

    /// A row not imported, its number in the file (the header row being 1).
    public struct Skipped: Equatable, Sendable {
        public let row: Int
        public let reason: SkipReason
    }

    /// A row imported with one thing left out.
    public struct Warning: Equatable, Sendable {
        public let row: Int
        public let reason: WarningReason
    }

    public enum Failure: Error, Equatable, Sendable {
        /// No password column: this is not a file of logins, and nothing is guessed.
        case noLoginColumns
        /// A JSON file that is not an export of the manager it says it is, or not JSON.
        case notAnExport
        /// An export the manager protected with a password: Sunset reads the plain one.
        case encrypted
    }

    public let source: Source
    public let entries: [VaultEntry]
    public let skipped: [Skipped]
    public let warnings: [Warning]
    /// Logins left out because the vault, or the file earlier, has them.
    public let duplicates: Int

    /// `site` gives the registrable domain of a host (the public suffix list's), for an entry's title when the file has none.
    public static func read(_ text: String, site: (String) -> String?) throws(Failure) -> Self {
        let rows = CSVReader.rows(text)
        guard let header = rows.first else { throw .noLoginColumns }
        let layout = columns(of: header)
        guard layout[.password] != nil || layout[.type] != nil else { throw .noLoginColumns }
        var entries: [VaultEntry] = []
        var skipped: [Skipped] = []
        var warnings: [Warning] = []
        for (offset, cells) in rows.dropFirst().enumerated() {
            let number = offset + 2
            // A cell is the person's, as written: a title, a username, a note keep their spaces and line breaks. What is a token, not
            // text (an address, a code, a flag, the kind of an item), is read without the space round it.
            func cell(_ role: Role) -> String {
                layout[role].flatMap { $0 < cells.count ? cells[$0] : nil } ?? ""
            }
            func token(_ role: Role) -> String {
                cell(role).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if ["1", "true", "yes"].contains(token(.archived).lowercased()) {
                skipped.append(Skipped(row: number, reason: .archived))
                continue
            }
            if let type = layout[.type].map({ _ in token(.type).lowercased() }), !type.isEmpty, type != "login" {
                guard let item = csvItem(kind: type, cell: cell, token: token) else {
                    skipped.append(Skipped(row: number, reason: .notALogin))
                    continue
                }
                if item.expiryUnreadable { warnings.append(Warning(row: number, reason: .unreadableExpiry)) }
                entries.append(
                    Self.filed(item.entry, folder: cell(.folder), favorite: token(.favorite), tags: cell(.tags))
                )
                continue
            }
            let username = cell(.username)
            let password = layout[.password].flatMap { $0 < cells.count ? cells[$0] : nil } ?? ""
            guard !username.isEmpty || !password.isEmpty else {
                skipped.append(Skipped(row: number, reason: .empty))
                continue
            }
            let address = Self.address(token(.url))
            var entry = EntryTemplate.login.makeEntry(
                title: Self.entryTitle(cell(.title), address: address, username: username, site: site)
            )
            func put(_ name: String, _ value: String) {
                Self.put(name, value, in: &entry)
            }
            put("Website", address)
            put("Username", username)
            put("Password", password)
            let codeText = token(.code)
            if !codeText.isEmpty {
                if let link = Self.link(codeText, account: username, issuer: entry.title) {
                    put("One-Time Code", link)
                } else {
                    warnings.append(Warning(row: number, reason: .unreadableCode))
                }
            }
            entry.note = cell(.notes)
            entries.append(Self.filed(entry, folder: cell(.folder), favorite: token(.favorite), tags: cell(.tags)))
        }
        return Self(source: source(of: header), entries: entries, skipped: skipped, warnings: warnings, duplicates: 0)
    }

    /// Sets the field named `name` of `entry` to `value`, when there is a value and such a field.
    static func put(_ name: String, _ value: String, in entry: inout VaultEntry) {
        if !value.isEmpty, let field = entry.field(named: name)?.id { entry.set(field, value) }
    }

    /// `entry` with the folder, favourite flag and tags a row gives it.
    private static func filed(_ entry: VaultEntry, folder: String, favorite: String, tags: String) -> VaultEntry {
        var filed = entry
        filed.folder = folder.isEmpty ? nil : folder
        filed.isFavorite = ["1", "true", "yes"].contains(favorite.lowercased())
        filed.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return filed
    }

    /// What is not in `held` already, nor earlier in the file: a login is the same by its site, username and password; any other entry by
    /// its kind, title, fields and note.
    public func leavingOut(held: [VaultEntry], site: (String) -> String?) -> Self {
        func key(_ entry: VaultEntry) -> String? {
            if entry.template == EntryTemplate.login.id, let credentials = LoginMatch.credentials(of: entry) {
                let host = LoginMatch.website(of: entry)?.host()?.lowercased() ?? ""
                return [site(host) ?? host, credentials.username, credentials.password].joined(separator: "\u{1F}")
            }
            let values = entry.sections.flatMap(\.fields).map { "\($0.name)=\($0.value)" }
            return ([entry.template?.uuidString ?? "", entry.title, entry.note] + values).joined(separator: "\u{1F}")
        }
        var seen = Set(held.compactMap(key))
        var fresh: [VaultEntry] = []
        var duplicates = 0
        for entry in entries {
            if let key = key(entry), !seen.insert(key).inserted {
                duplicates += 1
            } else {
                fresh.append(entry)
            }
        }
        return Self(
            source: source,
            entries: fresh,
            skipped: skipped,
            warnings: warnings,
            duplicates: self.duplicates + duplicates
        )
    }

    /// The first address of a cell (a manager's export has several, one a line), with `https://` when it has no scheme.
    static func address(_ cell: String) -> String {
        let first = cell.split(whereSeparator: \.isNewline).first.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
        return first.isEmpty || first.contains("://") ? first : "https://" + first
    }

    private static func entryTitle(_ given: String, address: String, username: String, site: (String) -> String?)
        -> String
    {
        if !given.isEmpty { return given }
        if let host = URL(string: address)?.host()?.lowercased() { return site(host) ?? host }
        return address.isEmpty ? (username.isEmpty ? "Imported login" : username) : address
    }

    /// The link a code is kept as: an `otpauth://` or `steam://` link as it is, a bare Base32 secret made one; nil for anything else.
    static func link(_ text: String, account: String, issuer: String) -> String? {
        if (try? OneTimeCodeURI(text)) != nil { return text }
        let secret = text.filter { !$0.isWhitespace }
        guard let bytes = try? Base32.decode(secret), !bytes.isEmpty else { return nil }
        var code = (try? OneTimeCodeURI("otpauth://totp/x?secret=\(secret)")) ?? nil
        code?.account = account
        code?.issuer = issuer.isEmpty ? nil : issuer
        return code?.uri
    }
}
