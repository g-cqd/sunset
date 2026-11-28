internal import AemiJSONCore
public import Foundation
internal import OrderedCollections

/// 1Password's export (`.1pux`, roadmap 0095 E): a zip of `export.data` (its accounts, vaults and items as JSON) and
/// `files/` (attachments, as `<documentId>__<name>`). Each item made the vault's entry of its kind: logins (and
/// passwords), cards, identities, secure notes, documents, SSH keys; any other kind a secure note with every field kept.
/// Archived items are left out and counted. The file is read as 1Password documents it (support.1password.com,
/// "1Password Unencrypted Export (.1PUX) format"); it is in the clear, and Sunset leaves it where it is.
extension LoginImport {
    private typealias Object = OrderedDictionary<String, JSONValue>

    /// Whether `data` is a zip holding a 1Password export.
    public static func isOnePasswordExport(_ data: Data) -> Bool {
        data.prefix(4).elementsEqual([0x50, 0x4B, 3, 4]) && ZipReader.files(data)?["export.data"] != nil
    }

    public static func readOnePassword(_ data: Data, site: (String) -> String?) throws(Failure) -> Self {
        guard let files = ZipReader.files(data), let exportData = files["export.data"],
            let text = String(data: exportData, encoding: .utf8),
            case .object(let top) = try parseStrictJSON(text),
            case .array(let accounts)? = top["accounts"]
        else { throw .notAnExport }
        // The attachments by their document's id.
        var attachments: [String: (name: String, data: Data)] = [:]
        for (path, data) in files where path.hasPrefix("files/") {
            let name = String(path.dropFirst("files/".count))
            guard let split = name.range(of: "__") else { continue }
            attachments[String(name[..<split.lowerBound])] = (String(name[split.upperBound...]), data)
        }
        let vaults = accounts.flatMap { account -> [Object] in
            guard case .object(let account) = account, case .array(let vaults)? = account["vaults"] else { return [] }
            return vaults.compactMap { if case .object(let vault) = $0 { vault } else { nil } }
        }
        var entries: [VaultEntry] = []
        var skipped: [Skipped] = []
        var warnings: [Warning] = []
        var number = 0
        for vault in vaults {
            let name = Self.onePasswordName(vault)
            guard case .array(let items)? = vault["items"] else { continue }
            for case .object(let item) in items {
                number += 1
                if case .string(let state)? = item["state"], state != "active" {
                    skipped.append(Skipped(row: number, reason: state == "archived" ? .archived : .deleted))
                    continue
                }
                var made = OnePasswordItem(item, site: site, attachments: attachments)
                made.entry.folder = vaults.count > 1 ? name : made.entry.folder
                if made.unreadableCode { warnings.append(Warning(row: number, reason: .unreadableCode)) }
                entries.append(made.entry)
            }
        }
        return Self(source: .onePassword, entries: entries, skipped: skipped, warnings: warnings, duplicates: 0)
    }

    /// A vault's name: its `attrs.name`.
    private static func onePasswordName(_ vault: Object) -> String? {
        guard case .object(let attributes)? = vault["attrs"] else { return nil }
        return jsonText(attributes["name"]).flatMap { $0.isEmpty ? nil : $0 }
    }
}
