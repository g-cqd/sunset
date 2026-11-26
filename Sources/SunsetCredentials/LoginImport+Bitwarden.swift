internal import AemiJSONCore
import Foundation
internal import OrderedCollections

/// Bitwarden's JSON export, the plain one (roadmap 0095 E): its folders and items, each item a login, a secure note, a card or an identity,
/// each made the vault's own entry of that kind. The file is read by AemiJSON, strictly: RFC 8259, no key twice, no more than 32 levels deep.
/// What is not understood is left out and said, never guessed. The shape is Bitwarden's documented export as remembered, not a file checked.
extension LoginImport {
    private typealias Object = OrderedDictionary<String, JSONValue>

    /// One JSON object, read by key: its text (a number is its digits), absent or empty as nil.
    private struct Fields {
        let object: Object

        init?(_ value: JSONValue?) {
            guard case .object(let object)? = value else { return nil }
            self.object = object
        }

        func text(_ key: String) -> String? {
            LoginImport.jsonText(object[key]).flatMap { $0.isEmpty ? nil : $0 }
        }

        subscript(key: String) -> JSONValue? {
            object[key]
        }
    }

    /// The kinds of item of an export (`type`).
    private enum ItemKind: Int {
        case login = 1
        case secureNote, card, identity
    }

    /// A file chosen by the person, read as what it is: JSON that opens with an object or a list is sniffed across
    /// Bitwarden, Aegis, 2FAS, and andOTP; anything else is CSV.
    public static func readFile(_ text: String, site: (String) -> String?) throws(Failure) -> Self {
        let opening = text.drop { $0 == "\u{FEFF}" || $0.isWhitespace }.first
        return opening == "{" || opening == "[" ? try readJSON(text, site: site) : try read(text, site: site)
    }

    /// Sniffs JSON exports (Bitwarden, Aegis, 2FAS, andOTP) using strict RFC 8259 AemiJSON parsing (no duplicate keys,
    /// max depth 32).
    public static func readJSON(_ text: String, site: (String) -> String?) throws(Failure) -> Self {
        switch try parseStrictJSON(text) {
            case .array(let list): return try readAndOTP(list)
            case .object(let top) where top["items"] != nil || top["encrypted"] != nil:
                return try readBitwardenObject(top, site: site)
            case .object(let top) where top["db"] != nil: return try readAegisObject(top)
            case .object(let top) where top["services"] != nil || top["servicesEncrypted"] != nil:
                return try read2FASObject(top)
            default: throw .notAnExport
        }
    }

    public static func readBitwarden(_ text: String, site: (String) -> String?) throws(Failure) -> Self {
        guard case .object(let top) = try parseStrictJSON(text) else { throw .notAnExport }
        return try readBitwardenObject(top, site: site)
    }

    /// Reads a Bitwarden password-protected JSON export (`encrypted: true`, `passwordProtected: true`, roadmap 0095 E)
    /// using `password` (supports both PBKDF2-HMAC-SHA256 and Argon2id KDFs). Throws `.encrypted` on wrong password.
    public static func readEncryptedBitwarden(
        _ text: String,
        password: String,
        site: (String) -> String?
    ) throws(Failure) -> Self {
        let plain = try BitwardenEncryptedExport.decrypt(text, password: password)
        return try readBitwarden(plain, site: site)
    }

    /// True when `text` is a Bitwarden password-protected JSON export that can be opened with `readEncryptedBitwarden`.
    public static func isPasswordProtectedBitwarden(_ text: String) -> Bool {
        BitwardenEncryptedExport.isPasswordProtected(text)
    }

    private static func readBitwardenObject(_ top: Object, site: (String) -> String?) throws(Failure) -> Self {
        if case .bool(true)? = top["encrypted"] { throw .encrypted }
        guard case .array(let items)? = top["items"] else { throw .notAnExport }
        let folders = folderNames(top["folders"])
        var entries: [VaultEntry] = []
        var skipped: [Skipped] = []
        var warnings: [Warning] = []
        for (offset, item) in items.enumerated() {
            let number = offset + 1
            guard case .object(let object) = item, case .int(let type)? = object["type"],
                let kind = ItemKind(rawValue: Int(clamping: type))
            else {
                skipped.append(Skipped(row: number, reason: .unknownKind))
                continue
            }
            if let deleted = jsonText(object["deletedDate"]), !deleted.isEmpty {
                skipped.append(Skipped(row: number, reason: .deleted))
                continue
            }
            var made = Made(title: jsonText(object["name"]) ?? "")
            switch kind {
                case .login: made.login(object["login"], title: made.title, site: site)
                case .secureNote: made.entry = EntryTemplate.secureNote.makeEntry(title: made.title)
                case .card: made.card(object["card"])
                case .identity: made.identity(object["identity"])
            }
            made.customFields(object["fields"])
            made.entry.note = jsonText(object["notes"]) ?? ""
            made.entry.isFavorite = object["favorite"].map { if case .bool(true) = $0 { true } else { false } } ?? false
            made.entry.folder = jsonText(object["folderId"]).flatMap { folders[$0] }
            if made.expiryUnreadable { warnings.append(Warning(row: number, reason: .unreadableExpiry)) }
            if made.codeUnreadable { warnings.append(Warning(row: number, reason: .unreadableCode)) }
            entries.append(made.entry)
        }
        return Self(source: .bitwarden, entries: entries, skipped: skipped, warnings: warnings, duplicates: 0)
    }

    /// The text of a JSON value that is one; a whole number is its digits (a card number a program wrote as a number).
    static func jsonText(_ value: JSONValue?) -> String? {
        switch value {
            case .string(let text)?: text
            case .int(let number)?: String(number)
            default: nil
        }
    }

    static func folderNames(_ folders: JSONValue?) -> [String: String] {
        guard case .array(let list)? = folders else { return [:] }
        var names: [String: String] = [:]
        for case .object(let folder) in list {
            if let id = jsonText(folder["id"]), let name = jsonText(folder["name"]), !name.isEmpty { names[id] = name }
        }
        return names
    }

    /// One item being turned into an entry.
    private struct Made {
        var title: String
        var entry: VaultEntry
        var expiryUnreadable = false
        var codeUnreadable = false

        init(title: String) {
            self.title = title
            entry = EntryTemplate.login.makeEntry(title: title)
        }

        mutating func put(_ name: String, _ value: String?) {
            if let value, !value.isEmpty, let field = entry.field(named: name)?.id { entry.set(field, value) }
        }

        /// `value` into the field named `name` when there is one; else `flag` is raised, for the warning that something was left out.
        mutating func putOrFlag(_ name: String, _ value: String?, _ flag: WritableKeyPath<Self, Bool>) {
            if let value { put(name, value) } else { self[keyPath: flag] = true }
        }

        /// The fields of the template named in `pairs` (its name, the key of the export), each from `fields`.
        mutating func put(from fields: Fields, _ pairs: [(name: String, key: String)]) {
            for (name, key) in pairs { put(name, fields.text(key)) }
        }

        /// A field the template has no place for, at the end of the first section.
        mutating func extra(_ name: String, _ value: String?, kind: FieldKind = .text) {
            guard let value, !value.isEmpty else { return }
            let section = entry.sections.first?.id ?? entry.addSection(title.isEmpty ? "Details" : title)
            entry.add(EntryField(name: name, kind: kind, value: value), to: section)
        }

        mutating func login(_ login: JSONValue?, title: String, site: (String) -> String?) {
            guard let login = Fields(login) else { return }
            let username = login.text("username") ?? ""
            put("Username", username)
            put("Password", login.text("password"))
            var addresses: [String] = []
            if case .array(let uris)? = login["uris"] {
                addresses = uris.compactMap { Fields($0)?.text("uri") }.map { LoginImport.address($0) }
            }
            put("Website", addresses.first)
            for (index, address) in addresses.dropFirst().enumerated() {
                extra("Website \(index + 2)", address, kind: .url)
            }
            oneTimeCode(login.text("totp"), account: username, issuer: title)
        }

        /// The one-time code of a login: a link as it is, a bare secret made one; flagged when it is neither.
        private mutating func oneTimeCode(_ text: String?, account: String, issuer: String) {
            guard let code = text?.trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty else { return }
            putOrFlag("One-Time Code", LoginImport.link(code, account: account, issuer: issuer), \.codeUnreadable)
        }

        mutating func card(_ card: JSONValue?) {
            entry = EntryTemplate.card.makeEntry(title: title)
            guard let card = Fields(card) else { return }
            put(from: card, [("Cardholder", "cardholderName"), ("Number", "number"), ("Security Code", "code")])
            extra("Brand", card.text("brand"))
            expiry(month: card.text("expMonth"), year: card.text("expYear"))
        }

        /// A card's expiry as `YYYY-MM`; flagged when what the export has is not a month and a year.
        private mutating func expiry(month: String?, year: String?) {
            guard month != nil || year != nil else { return }
            putOrFlag("Expiry", LoginImport.expiry(month: month ?? "", year: year ?? ""), \.expiryUnreadable)
        }

        mutating func identity(_ identity: JSONValue?) {
            entry = EntryTemplate.identity.makeEntry(title: title)
            guard let person = Fields(identity) else { return }
            put(
                "First Name",
                [person.text("firstName"), person.text("middleName")].compactMap(\.self).joined(separator: " ")
            )
            let names = ["Last Name", "Email", "Phone", "City", "Postal Code", "Region", "Country"]
            let keys = ["lastName", "email", "phone", "city", "postalCode", "state", "country"]
            put(from: person, Array(zip(names, keys)))
            put("Street", ["address1", "address2", "address3"].compactMap { person.text($0) }.joined(separator: "\n"))
            for (name, key) in [("Title", "title"), ("Company", "company"), ("Username", "username")] {
                extra(name, person.text(key))
            }
            for (name, key) in [
                ("SSN", "ssn"), ("Passport Number", "passportNumber"), ("License Number", "licenseNumber")
            ] {
                extra(name, person.text(key), kind: .concealed)
            }
        }

        /// The custom fields of an item, in a section of their own: text, hidden (kept hidden) and yes-or-no (as text).
        mutating func customFields(_ fields: JSONValue?) {
            guard case .array(let list)? = fields else { return }
            var section: UUID?
            for case .object(let field) in list {
                guard let name = LoginImport.jsonText(field["name"]), !name.isEmpty,
                    case .int(let type)? = field["type"], type <= 2
                else {
                    continue
                }
                let id = section ?? entry.addSection("Custom Fields")
                section = id
                let kind: FieldKind = type == 1 ? .concealed : .text
                entry.add(EntryField(name: name, kind: kind, value: LoginImport.jsonText(field["value"]) ?? ""), to: id)
            }
        }
    }

    /// `YYYY-MM` from a month and a year as a manager writes them ("4", "04"; "2030", "30"); nil when either is not one.
    static func expiry(month: String, year: String) -> String? {
        guard let month = Int(month), (1 ... 12).contains(month), let year = Int(year), year >= 0 else { return nil }
        let full = year < 100 ? 2000 + year : year
        guard (1000 ... 9999).contains(full) else { return nil }
        return String(format: "%04d-%02d", full, month)
    }
}
