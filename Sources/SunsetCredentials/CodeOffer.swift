public import Foundation

/// What a page's one-time code field is offered (roadmap 0094 F): each entry for the page's site with a code that reads,
/// and that code's field, to read its code now.
public struct CodeOffer: Sendable {
    public let entry: VaultEntry
    public let field: OneTimeCodeField

    /// The page's site's entries with a code, the page's exact host first (as `LoginMatch`); any entry with a website,
    /// not only a login.
    public static func offered(_ entries: [VaultEntry], for page: URL?, site: (String) -> String?) -> [CodeOffer] {
        let withCode: [CodeOffer] = entries.compactMap { entry in
            let value = entry.sections.flatMap(\.fields).first { $0.kind == .oneTimeCode && !$0.value.isEmpty }?.value
            return value.flatMap(OneTimeCodeField.init).map { CodeOffer(entry: entry, field: $0) }
        }
        let matched = LoginMatch.sited(withCode.map(\.entry), for: page, site: site)
        return matched.compactMap { entry in withCode.first { $0.entry.id == entry.id } }
    }
}
