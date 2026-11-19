package import Foundation

/// What Sunset fetches for a page (a site's icon, a notification's picture): the page names it, so it is the page's input
/// (white paper §9). Only from the web or a `data:` address (never a file of the Mac), as the browser the site is shown,
/// without cookies, and never more than a limit is read.
package enum WebFetch {
    /// Whether a page may have Sunset fetch `address`.
    package static func allows(_ address: URL) -> Bool {
        ["http", "https", "data"].contains(address.scheme?.lowercased() ?? "")
    }

    /// The bytes at `address` and the response; nil when it may not be fetched, failed, or is longer than `limit`.
    /// - Parameters:
    ///   - address: What the page named.
    ///   - agent: The user agent the page's site is shown.
    ///   - limit: The most bytes read.
    /// - Returns: The bytes and the response, or nil.
    package static func data(_ address: URL, agent: String, limit: Int) async -> (data: Data, response: URLResponse)? {
        guard allows(address) else { return nil }
        var request = URLRequest(url: address.absoluteURL)
        request.setValue(agent, forHTTPHeaderField: "User-Agent")
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        guard let (bytes, response) = try? await session.bytes(for: request) else { return nil }
        if response.expectedContentLength > Int64(limit) {
            bytes.task.cancel()
            return nil
        }
        var data = Data()
        do {
            for try await byte in bytes {
                guard data.count < limit else {
                    bytes.task.cancel()
                    return nil
                }
                data.append(byte)
            }
        } catch {
            return nil
        }
        return (data, response)
    }
}
