public import Foundation

/// What a password sent asks (roadmap 0094 D): nothing when the vault has it already for the site, or the person said
/// never for the site; to update the password of the site's entry with that username; else to save a new login.
public enum LoginSave {
    public enum Offer: Equatable, Sendable {
        case save
        case update(UUID)
    }

    public static func offer(
        for sent: SentLoginValues,
        in entries: [VaultEntry],
        never: Set<String>,
        site: (String) -> String?
    ) -> Offer? {
        guard let host = sent.origin.host()?.lowercased(), let pageSite = site(host), !never.contains(pageSite) else {
            return nil
        }
        let ofSite = LoginMatch.offered(entries, for: sent.origin, site: site)
        let same = ofSite.filter { LoginMatch.credentials(of: $0)?.username == sent.username }
        if same.contains(where: { LoginMatch.credentials(of: $0)?.password == sent.password }) { return nil }
        if let entry = same.first { return .update(entry.id) }
        return .save
    }

    /// A new login for what was sent: titled for its site, its website the page's origin.
    public static func entry(for sent: SentLoginValues, site: (String) -> String?) -> VaultEntry {
        let host = sent.origin.host()?.lowercased() ?? ""
        var entry = EntryTemplate.login.makeEntry(title: site(host) ?? host)
        for (name, value) in [
            ("Website", sent.origin.absoluteString), ("Username", sent.username), ("Password", sent.password)
        ] {
            if let field = entry.field(named: name)?.id { entry.set(field, value) }
        }
        return entry
    }

    /// `entry` with its password now `password`.
    public static func updated(_ entry: VaultEntry, password: String) -> VaultEntry {
        var entry = entry
        if let field = entry.sections.flatMap(\.fields).first(where: { $0.kind == .concealed })?.id {
            entry.set(field, password)
        }
        return entry
    }
}
