public import Foundation

/// Which entries a page is offered (roadmap 0094 B, ADR-0094): the logins (an entry with a website and a password) whose
/// website's site (its registrable domain, `site`: the Public Suffix List's) is the page's; the page's exact host first,
/// then by title. A look-alike host is another site, so never offered. An entry saved for https is not offered on an
/// http page (the page could be anyone's); one saved for http is offered on both. Only http and https pages.
public enum LoginMatch {
    public static func offered(_ entries: [VaultEntry], for page: URL?, site: (String) -> String?) -> [VaultEntry] {
        guard let page, let scheme = page.scheme?.lowercased(), ["http", "https"].contains(scheme),
            let host = page.host()?.lowercased(), let pageSite = site(host)
        else { return [] }
        let matched: [(entry: VaultEntry, exact: Bool)] = entries.compactMap { entry in
            guard credentials(of: entry) != nil, let website = website(of: entry),
                let entryHost = website.host()?.lowercased(), site(entryHost) == pageSite,
                scheme == "https" || website.scheme?.lowercased() == "http"
            else { return nil }
            return (entry, entryHost == host)
        }
        return
            matched.sorted {
                $0.exact != $1.exact
                    ? $0.exact : $0.entry.title.localizedStandardCompare($1.entry.title) == .orderedAscending
            }
            .map(\.entry)
    }

    /// Its username and password; nil for an entry without a password.
    public static func credentials(of entry: VaultEntry) -> LoginCredentials? {
        let fields = entry.sections.flatMap(\.fields)
        guard let password = fields.first(where: { $0.kind == .concealed && !$0.value.isEmpty })?.value else {
            return nil
        }
        let username = (entry.field(named: "Username") ?? fields.first { $0.kind == .email || $0.kind == .text })?.value
        return LoginCredentials(username: username ?? "", password: password)
    }

    /// Its website as a URL: a value without a scheme is https.
    static func website(of entry: VaultEntry) -> URL? {
        guard let value = entry.sections.flatMap(\.fields).first(where: { $0.kind == .url && !$0.value.isEmpty })?.value
        else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return URL(string: trimmed.contains("://") ? trimmed : "https://" + trimmed)
    }
}
