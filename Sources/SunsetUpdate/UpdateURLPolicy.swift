public import Foundation

/// Pins update fetches to GitHub over HTTPS (ADR-0125) so a tampered feed cannot redirect Sunset to arbitrary hosts or
/// plaintext HTTP. Local testing bypasses this only when `$SUNSET_UPDATES_FEED` is explicitly set.
public enum UpdateURLPolicy {
    private static let allowedRepoPrefixes = [
        "https://github.com/g-cqd/sunset/",
        "https://api.github.com/repos/g-cqd/sunset/"
    ]
    private static let allowedAssetHosts: Set<String> = [
        "release-assets.githubusercontent.com",
        "objects.githubusercontent.com"
    ]

    /// Whether `url` may be fetched by the updater.
    public static func isAllowed(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", let host = url.host()?.lowercased() else { return false }
        if allowedAssetHosts.contains(host) { return true }
        let full = url.absoluteString
        return allowedRepoPrefixes.contains { full.hasPrefix($0) }
    }
}
