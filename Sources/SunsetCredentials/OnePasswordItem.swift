internal import AemiJSONCore
import Foundation
internal import OrderedCollections

/// One item of a 1Password export made the vault's own (`LoginImport.readOnePassword`).
struct OnePasswordItem {
    typealias Object = OrderedDictionary<String, JSONValue>

    var entry: VaultEntry
    var unreadableCode = false

    /// 1Password's categories (`categoryUuid`) and the template each becomes; any other: a secure note.
    private static let templates: [String: EntryTemplate] = [
        "001": .login, "005": .login, "002": .card, "003": .secureNote, "004": .identity, "006": .secureNote,
        "114": EntryTemplate.shipped[5]
    ]

    /// The fields of a section whose ids are the template's, by the template's names: `id=Name`, one a line.
    private static let named: [String: String] = Dictionary(
        uniqueKeysWithValues: """
            cardholder=Cardholder
            ccnum=Number
            cvv=Security Code
            expiry=Expiry
            pin=PIN
            firstname=First Name
            lastname=Last Name
            email=Email
            defphone=Phone
            birthdate=Birthday
            address=Street
            private_key=Private Key
            public_key=Public Key
            """
            .split(separator: "\n")
            .map { line in
                let pair = line.split(separator: "=", maxSplits: 1).map(String.init)
                return (pair[0], pair[1])
            }
    )

    init(_ item: Object, site: (String) -> String?, attachments: [String: (name: String, data: Data)]) {
        let overview = Self.object(item["overview"])
        let details = Self.object(item["details"])
        let category = LoginImport.jsonText(item["categoryUuid"]) ?? ""
        let template = Self.templates[category] ?? .secureNote
        let given = LoginImport.jsonText(overview["title"]) ?? ""
        let address = LoginImport.address(LoginImport.jsonText(overview["url"]) ?? "")
        let host = URL(string: address)?.host()?.lowercased()
        let title = !given.isEmpty ? given : host.map { site($0) ?? $0 } ?? "Imported item"
        entry = template.makeEntry(title: title)
        entry.note = LoginImport.jsonText(details["notesPlain"]) ?? ""
        if case .array(let tags)? = overview["tags"] { entry.tags = tags.compactMap(LoginImport.jsonText) }
        if case .int(let favourite)? = item["favIndex"] { entry.isFavorite = favourite > 0 }
        if template.id == EntryTemplate.login.id { fillLogin(details, address: address) }
        addSections(details, attachments: attachments)
        addDocument(details, attachments: attachments)
    }

    private static func object(_ value: JSONValue?) -> Object {
        if case .object(let object)? = value { object } else { [:] }
    }

    /// Its username and password (the login fields 1Password designates), its address, and its password's history.
    private mutating func fillLogin(_ details: Object, address: String) {
        if case .array(let fields)? = details["loginFields"] {
            for case .object(let field) in fields {
                let value = LoginImport.jsonText(field["value"]) ?? ""
                switch LoginImport.jsonText(field["designation"]) {
                    case "username": LoginImport.put("Username", value, in: &entry)
                    case "password": LoginImport.put("Password", value, in: &entry)
                    default: continue
                }
            }
        }
        LoginImport.put("Website", address, in: &entry)
        guard let field = entry.field(named: "Password")?.id, case .array(let history)? = details["passwordHistory"]
        else { return }
        let earlier =
            history.compactMap { value -> FieldHistoryItem? in
                guard case .object(let old) = value, let text = LoginImport.jsonText(old["value"]), !text.isEmpty else {
                    return nil
                }
                var time: TimeInterval = 0
                if case .int(let seconds)? = old["time"] { time = TimeInterval(seconds) }
                return FieldHistoryItem(value: text, changedAt: Date(timeIntervalSince1970: time))
            }
            .sorted { $0.changedAt < $1.changedAt }
        if !earlier.isEmpty { entry.setHistory(of: field, Array(earlier.suffix(EntryField.historyLimit))) }
    }

    /// Its sections' fields: into the template's field of that meaning, else a field of their own in a section of their
    /// own; a one-time code into the login's.
    private mutating func addSections(_ details: Object, attachments: [String: (name: String, data: Data)]) {
        guard case .array(let sections)? = details["sections"] else { return }
        for case .object(let section) in sections {
            guard case .array(let fields)? = section["fields"] else { continue }
            var own: UUID?
            for case .object(let field) in fields {
                let id = LoginImport.jsonText(field["id"]) ?? ""
                guard let value = OnePasswordValue(Self.object(field["value"])) else { continue }
                if case .file(let document) = value {
                    attach(document, attachments: attachments)
                    continue
                }
                if value.kind == .oneTimeCode, entry.field(named: "One-Time Code") != nil {
                    if let link = LoginImport.link(value.text, account: "", issuer: entry.title) {
                        LoginImport.put("One-Time Code", link, in: &entry)
                    } else {
                        unreadableCode = true
                    }
                    continue
                }
                if let name = Self.named[id], let target = entry.field(named: name), target.value.isEmpty {
                    LoginImport.put(name, value.text, in: &entry)
                    continue
                }
                guard !value.text.isEmpty else { continue }
                let title = LoginImport.jsonText(field["title"]).flatMap { $0.isEmpty ? nil : $0 } ?? id
                let sectionTitle = LoginImport.jsonText(section["title"]).flatMap { $0.isEmpty ? nil : $0 } ?? "Details"
                let place = own ?? entry.addSection(sectionTitle)
                own = place
                entry.add(EntryField(name: title, kind: value.kind, value: value.text), to: place)
            }
        }
    }

    /// A Document item's file.
    private mutating func addDocument(_ details: Object, attachments: [String: (name: String, data: Data)]) {
        guard case .object(let document)? = details["documentAttributes"] else { return }
        attach(LoginImport.jsonText(document["documentId"]) ?? "", attachments: attachments)
    }

    private mutating func attach(_ document: String, attachments: [String: (name: String, data: Data)]) {
        guard let file = attachments[document], file.data.count <= VaultAttachment.maxBytes else { return }
        entry.addAttachment(VaultAttachment(filename: file.name, data: file.data, addedAt: .distantPast))
    }
}
