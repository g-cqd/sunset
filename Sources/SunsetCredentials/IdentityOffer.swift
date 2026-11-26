import Foundation

/// What a page's contact or address field is offered (roadmap 0094, t103): every Identity of the vault with something to
/// fill (identities are not tied to a site), by title; its values by the HTML autofill token of the field each goes in
/// (`given-name`, `email`, `postal-code`, ...). An identity made before the template had its address in parts keeps its
/// one Address field, which is not filled: where its city or postal code ends is not known.
public struct IdentityOffer: Sendable {
    public let entry: VaultEntry
    public let values: [String: String]

    /// What its row says under the title: its email, else its name.
    public var detail: String {
        values["email"] ?? values["name"] ?? ""
    }

    /// The tokens, each from the Identity field of that name (`token=Field`).
    static let tokens: [(token: String, field: String)] =
        """
        given-name=First Name;family-name=Last Name;email=Email;tel=Phone;street-address=Street;address-level2=City;\
        postal-code=Postal Code;address-level1=Region;country=Country
        """
        .split(separator: ";")
        .map { pair in
            let parts = pair.split(separator: "=").map(String.init)
            return (parts[0], parts[1])
        }

    public static func offered(_ entries: [VaultEntry]) -> [IdentityOffer] {
        entries.compactMap { entry -> IdentityOffer? in
            guard entry.template == EntryTemplate.identity.id else { return nil }
            var values: [String: String] = [:]
            for (token, field) in tokens {
                let value = (entry.field(named: field)?.value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty { values[token] = value }
            }
            guard !values.isEmpty else { return nil }
            let name = [values["given-name"], values["family-name"]].compactMap(\.self).joined(separator: " ")
            if !name.isEmpty { values["name"] = name }
            // The street's lines, each for a field of one line.
            let lines = (values["street-address"] ?? "").split(whereSeparator: \.isNewline)
            for (index, line) in lines.prefix(3).enumerated() {
                values["address-line\(index + 1)"] = line.trimmingCharacters(in: .whitespaces)
            }
            return IdentityOffer(entry: entry, values: values)
        }
        .sorted { $0.entry.title.localizedStandardCompare($1.entry.title) == .orderedAscending }
    }
}
