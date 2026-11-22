package import Foundation

/// Which blocking lists are fetched, when again, and under what name they are kept (out of the app target, so tested):
/// only over HTTPS, again when older than four days (EasyList's own "Expires"), under a name made of the address's safe
/// characters.
package enum BlockingListPlan {
    /// How old a kept list may be before it is fetched again.
    package static let maxAge: TimeInterval = 4 * 24 * 3600

    /// The list's address when it may be fetched: HTTPS only, since a list in the clear could be changed on the way.
    package static func address(_ text: String) -> URL? {
        guard let url = URL(string: text), url.scheme?.lowercased() == "https", url.host?.isEmpty == false else {
            return nil
        }
        return url
    }

    /// Whether a list kept since `keptAt` (nil: not kept) is fetched again.
    package static func isStale(keptAt: Date?, now: Date) -> Bool {
        guard let keptAt else {
            return true
        }
        return now.timeIntervalSince(keptAt) > maxAge
    }

    /// A file name for a list's address: its letters and digits, anything else an underscore, the last 120 of them.
    package static func fileName(for address: String) -> String {
        String(address.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : "_" }.suffix(120))
            + ".txt"
    }
}
