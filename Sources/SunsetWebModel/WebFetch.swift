package import Foundation
internal import Network

/// What Sunset fetches itself for a page (a site's icon, a notification's picture) or for the user (a blocking list): a
/// page's input (white paper §9). Only the web or a `data:` address, never a file of the Mac; never more than `limit`; through
/// the proxy pages go through; and, for a page, only public addresses or the page's own host (as Private Network Access
/// keeps a public page from this Mac and the local network: the outside audit's HIGH-01, 2026-11-22).
package enum WebFetch {
    package static func allows(_ address: URL) -> Bool {
        ["http", "https", "data"].contains(address.scheme?.lowercased() ?? "")
    }

    /// Fetches `address` for `page` (nil: an address the user gave, not a page's), through `proxy` when there is one.
    @concurrent package static func data(
        _ address: URL,
        agent: String,
        limit: Int,
        for page: URL?,
        proxy: WebProxy? = nil
    ) async -> (data: Data, response: URLResponse)? {
        guard allows(address), reaches(address, for: page, proxied: proxy != nil) else { return nil }
        var request = URLRequest(url: address.absoluteURL)
        request.setValue(agent, forHTTPHeaderField: "User-Agent")
        let configuration = URLSessionConfiguration.ephemeral
        if let proxy { configuration.proxyConfigurations = [proxy.configuration] }
        let delegate = FetchDelegate(limit: limit, page: page, proxied: proxy != nil)
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        return await delegate.run(session.dataTask(with: request))
    }

    /// Whether `address` may be fetched for `page`: a `data:` address, any address the user gave, the page's own host, or a
    /// host at public addresses only. Through a proxy a name is not looked up here (the proxy does, and the lookup would tell
    /// the local network what the proxy is there to hide); an address written as one is still checked. Blocks while a name
    /// is looked up.
    package static func reaches(_ address: URL, for page: URL?, proxied: Bool) -> Bool {
        let scheme = address.scheme?.lowercased() ?? ""
        guard scheme != "data" else { return true }
        guard ["http", "https"].contains(scheme), let host = address.host()?.lowercased(), !host.isEmpty else {
            return false
        }
        guard let page else { return true }
        if host == page.host()?.lowercased() { return true }
        if let literal = PublicAddress.literal(host) { return PublicAddress.isPublic(literal) }
        if proxied { return true }
        let resolved = PublicAddress.resolve(host)
        return !resolved.isEmpty && resolved.allSatisfy(PublicAddress.isPublic)
    }
}
