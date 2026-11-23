internal import CryptoKit
package import Foundation
package import WebKit

/// Resolves the `WKWebsiteDataStore` for a profile (ADR-0125): on the Native variant (system WebKit), uses `.default()`
/// for the primary profile and `profile` directly for others; on Sunset's bundled WebKit variant, derives a deterministic
/// per-variant UUID so newer WebKit IndexedDB schemas never collide with or corrupt macOS's older system WebKit on
/// downgrade, while preserving sessions if the user switches back.
package enum VariantStore {
    /// Whether this process is running Sunset's bundled WebKit variant (Info.plist carries `SunsetWebKitBase`).
    package static var usesBundledWebKit: Bool {
        Bundle.main.infoDictionary?["SunsetWebKitBase"] != nil
    }

    /// Deterministic UUID for the bundled WebKit variant's data store for `profile` (`nil` = primary profile).
    package static func bundledIdentifier(for profile: UUID?) -> UUID {
        let seed = "studio.aemi.sunset.webkit-variant:" + (profile?.uuidString ?? "default")
        var raw = Array(SHA256.hash(data: Data(seed.utf8)).prefix(16))
        raw[6] = (raw[6] & 0x0F) | 0x50
        raw[8] = (raw[8] & 0x3F) | 0x80
        let uuid: uuid_t = raw.withUnsafeBytes { buffer in
            unsafe buffer.load(as: uuid_t.self)
        }
        return UUID(uuid: uuid)
    }

    /// The persistent `WKWebsiteDataStore` for `profile` (`nil` = primary profile) in the running engine variant.
    @MainActor
    package static func store(for profile: UUID?) -> WKWebsiteDataStore {
        if usesBundledWebKit {
            return WKWebsiteDataStore(forIdentifier: bundledIdentifier(for: profile))
        }
        return profile.map { WKWebsiteDataStore(forIdentifier: $0) } ?? .default()
    }
}
