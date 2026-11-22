package import AppKit
import Foundation
package import Observation
import SunsetRuntime
package import SunsetStorage

/// The sites' icons, kept: a tab that is not loaded, or was not yet this run, shows its site's icon. Kept as sealed
/// records of the state database (one per host, the icon made small), read back at launch; each until the server said it
/// expires, then fetched again the next time a page of the site loads (and shown meanwhile). Private pages keep nothing.
/// Cleared with the history.
@MainActor @Observable
package final class FaviconStore {
    package static let shared = FaviconStore()

    /// The side, in pixels, an icon is kept at: what a tab draws, at twice its size, and no more.
    package static let side = 64
    /// How long an icon is kept when the server does not say.
    package static let defaultLife: TimeInterval = 7 * 24 * 3600
    /// The longest an icon is kept before it is asked for again, whatever the server says.
    package static let longestLife: TimeInterval = 30 * 24 * 3600

    struct Kept: Codable {
        var host: String
        var source: String?
        var png: Data
        var expires: Double
    }

    private var kept: [String: Kept] = [:]
    @ObservationIgnored private var images: [String: NSImage] = [:]
    @ObservationIgnored package var table: SealedTable? {
        didSet {
            load()
        }
    }

    package init() {}

    /// Where a profile's icon of a site is kept: by profile and host (a site can say something of the page shown through
    /// its icon, which another profile's page of the same site does not share). The first profile's (nil) is the host
    /// alone, as icons were kept before.
    static func key(host: String, profile: UUID?) -> String {
        profile.map { "\($0.uuidString)/\(host.lowercased())" } ?? host.lowercased()
    }

    /// The site's icon for the profile, if one is kept; expired or not (it shows until a new one comes).
    package func image(for host: String, profile: UUID? = nil) -> NSImage? {
        let key = Self.key(host: host, profile: profile)
        guard let entry = kept[key] else { return nil }
        if let image = images[key] { return image }
        let image = NSImage(data: entry.png)
        images[key] = image
        return image
    }

    /// Whether the icon kept for the site is the one the page names (when it names one) and has not expired.
    package func isFresh(host: String, profile: UUID? = nil, source: URL?, at now: Date = Runtime.live.now()) -> Bool {
        guard let entry = kept[Self.key(host: host, profile: profile)], entry.expires > now.timeIntervalSince1970 else {
            return false
        }
        guard let source else { return true }
        return entry.source == source.absoluteString
    }

    /// Keeps the site's icon, made small, in place of the one there was. False when `data` is not a picture.
    @discardableResult
    package func keep(host: String, profile: UUID? = nil, source: URL?, data: Data, expires: Date) -> Bool {
        guard let png = Self.small(data) else { return false }
        let key = Self.key(host: host, profile: profile)
        let entry = Kept(host: key, source: source?.absoluteString, png: png, expires: expires.timeIntervalSince1970)
        kept[key] = entry
        images[key] = nil
        if let payload = try? JSONEncoder().encode(entry) { table?.put(key, payload: payload) }
        return true
    }

    /// Forgets every icon, here and in the file (clearing the history).
    package func forgetAll() {
        kept = [:]
        images = [:]
        table?.removeAll()
    }

    /// When an icon the server sent expires: its `Cache-Control` max-age, else its `Expires`, else a week; at once for
    /// no-store and no-cache; never later than `longestLife`.
    package static func expiry(of response: HTTPURLResponse?, at now: Date) -> Date {
        let control = (response?.value(forHTTPHeaderField: "Cache-Control") ?? "").lowercased()
        let directives = control.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if directives.contains("no-store") || directives.contains("no-cache") { return now }
        var life = defaultLife
        if let age = directives.first(where: { $0.hasPrefix("max-age=") }).flatMap({ Double($0.dropFirst(8)) }) {
            life = age
        } else if let expires = response?.value(forHTTPHeaderField: "Expires").flatMap(httpDate) {
            life = expires.timeIntervalSince(now)
        }
        return now + min(max(life, 0), longestLife)
    }

    private static func httpDate(_ text: String) -> Date? {
        let format = DateFormatter()
        format.locale = Locale(identifier: "en_US_POSIX")
        format.timeZone = TimeZone(identifier: "GMT")
        format.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return format.date(from: text)
    }

    /// The picture as a PNG no larger than `side` on its longer edge (`FaviconStore.side` by default); nil when it is not a
    /// picture.
    package static func small(_ data: Data, side: Int = side) -> Data? {
        guard let image = NSImage(data: data), image.isValid,
            let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }
        let scale = min(1, Double(side) / Double(max(source.width, source.height, 1)))
        let width = max(Int((Double(source.width) * scale).rounded()), 1)
        let height = max(Int((Double(source.height) * scale).rounded()), 1)
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let made = context.makeImage() else { return nil }
        return NSBitmapImageRep(cgImage: made).representation(using: .png, properties: [:])
    }

    private func load() {
        kept = [:]
        images = [:]
        for row in table?.all().rows ?? [] {
            guard let entry = try? JSONDecoder().decode(Kept.self, from: row.payload) else { continue }
            kept[entry.host] = entry
        }
    }
}
