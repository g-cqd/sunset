/// How a site is named in what Sunset keeps per site (the browser it is shown, a pause of blocking): its host, in lower
/// case, without "www.", so that a site with and without it is one entry.
enum SiteHost {
    static func key(_ host: String) -> String {
        let lower = host.lowercased()
        return lower.hasPrefix("www.") ? String(lower.dropFirst(4)) : lower
    }
}
