import Foundation

/// One KeePass entry made the vault's own (`LoginImport.readKeePass`).
struct KeePassEntry {
    var entry: VaultEntry
    var unreadableCode = false

    /// The strings KeePass gives a meaning of its own: not custom fields.
    private static let standard: Set<String> = ["Title", "UserName", "Password", "URL", "Notes"]
    /// The one-time code's, as KeePassXC and KeePass write it.
    private static let codeKeys = ["otp", "TimeOtp-Secret-Base32", "TOTP Seed"]

    init(_ item: KeePassXML.Entry, attachments: [Data], now: Date, site: (String) -> String?) {
        let username = item.string("UserName")
        let password = item.string("Password")
        let address = LoginImport.address(item.string("URL"))
        let isLogin = !username.isEmpty || !password.isEmpty || !address.isEmpty
        let given = item.string("Title")
        let host = URL(string: address)?.host()?.lowercased()
        let title =
            !given.isEmpty ? given : host.map { site($0) ?? $0 } ?? (username.isEmpty ? "Imported entry" : username)
        entry = (isLogin ? EntryTemplate.login : EntryTemplate.secureNote).makeEntry(title: title)
        entry.note = item.string("Notes")
        entry.folder = item.groups.isEmpty ? nil : item.groups.joined(separator: " / ")
        entry.tags = item.tags.filter { !$0.isEmpty }
        if isLogin { fillLogin(item, username: username, password: password, address: address) }
        addCustomFields(item)
        entry.attachments = item.binaries.compactMap { binary in
            guard attachments.indices.contains(binary.reference) else { return nil }
            let data = attachments[binary.reference]
            guard data.count <= VaultAttachment.maxBytes else { return nil }
            return VaultAttachment(filename: binary.name, data: data, addedAt: now)
        }
    }

    private mutating func fillLogin(_ item: KeePassXML.Entry, username: String, password: String, address: String) {
        LoginImport.put("Website", address, in: &entry)
        LoginImport.put("Username", username, in: &entry)
        LoginImport.put("Password", password, in: &entry)
        // The passwords it had before, oldest first, as the field's history.
        if let field = entry.field(named: "Password")?.id {
            var earlier: [FieldHistoryItem] = []
            for version in item.history where !version.password.isEmpty && version.password != earlier.last?.value {
                earlier.append(FieldHistoryItem(value: version.password, changedAt: version.changed ?? .distantPast))
            }
            earlier.removeAll { $0.value == password }
            if !earlier.isEmpty { entry.setHistory(of: field, Array(earlier.suffix(EntryField.historyLimit))) }
        }
        if let code = Self.codeKeys.lazy.map(item.string).first(where: { !$0.isEmpty }) {
            if let link = LoginImport.link(code, account: username, issuer: entry.title) {
                LoginImport.put("One-Time Code", link, in: &entry)
            } else {
                unreadableCode = true
            }
        }
    }

    /// Its other strings, in a section of their own: hidden when KeePass protects them.
    private mutating func addCustomFields(_ item: KeePassXML.Entry) {
        let others = item.strings.filter { string in
            !Self.standard.contains(string.key) && !Self.codeKeys.contains(string.key)
                && !string.key.hasPrefix("TimeOtp-") && string.key != "TOTP Settings" && !string.value.isEmpty
        }
        guard !others.isEmpty else { return }
        let section = entry.addSection("Custom Fields")
        for string in others {
            let kind: FieldKind = string.protected ? .concealed : string.value.contains("\n") ? .multiline : .text
            entry.add(EntryField(name: string.key, kind: kind, value: string.value), to: section)
        }
    }
}
