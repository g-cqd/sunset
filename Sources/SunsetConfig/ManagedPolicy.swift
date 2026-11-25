public import Foundation

/// Organisation-enforced managed preferences (MDM configuration profiles, R-OPS-2 / Sprint 3).
/// Only keys explicitly forced by an administrator (`UserDefaults.objectIsForced(forKey:)`) take effect; local user
/// defaults never weaken or mimic organisation policy. A forced value of the wrong type fails closed.
public struct ManagedPolicy: Equatable, Sendable {
    public enum Key: String, CaseIterable, Sendable {
        case allowExtensions = "AllowExtensions"
        case allowCertificateExceptions = "AllowCertificateExceptions"
        case requireHardenedWeb = "RequireHardenedWeb"
        case requireHTTPSUpgrade = "RequireHTTPSUpgrade"
        case allowSafeDownloadAutoOpen = "AllowSafeDownloadAutoOpen"
        case maxVaultLockMinutes = "MaxVaultLockMinutes"
        case requireAutomaticUpdates = "RequireAutomaticUpdates"
    }

    /// The `Allow…` keys forced to anything other than `true`.
    public private(set) var denied: Set<Key> = []
    /// `RequireHardenedWeb` forced to anything other than `false`.
    public private(set) var requiresHardenedWeb = false
    /// `RequireHTTPSUpgrade` forced to anything other than `false`.
    public private(set) var requiresHTTPSUpgrade = false
    /// `RequireAutomaticUpdates` forced to anything other than `false`.
    public private(set) var requiresAutomaticUpdates = false
    /// Forced upper bound on `passwords.lockAfter` in minutes (> 0), or `nil` when not forced.
    public private(set) var maxVaultLockMinutes: Double?

    public init(forcedValue: (String) -> Any?) {
        for key in Key.allCases {
            guard let value = forcedValue(key.rawValue) else { continue }
            switch key {
                case .allowExtensions, .allowCertificateExceptions, .allowSafeDownloadAutoOpen:
                    if (value as? Bool) != true { denied.insert(key) }
                case .requireHardenedWeb:
                    requiresHardenedWeb = (value as? Bool) != false
                case .requireHTTPSUpgrade:
                    requiresHTTPSUpgrade = (value as? Bool) != false
                case .requireAutomaticUpdates:
                    requiresAutomaticUpdates = (value as? Bool) != false
                case .maxVaultLockMinutes:
                    maxVaultLockMinutes = Self.parseLockMinutes(value)
            }
        }
    }

    public init(reading defaults: UserDefaults) {
        self.init(forcedValue: { defaults.objectIsForced(forKey: $0) ? defaults.object(forKey: $0) : nil })
    }

    /// Reads the current managed preferences from `UserDefaults.standard`.
    public static var current: Self {
        Self(reading: .standard)
    }

    /// Whether an administrator forbids installing/loading browser extensions.
    public var forbidsExtensions: Bool {
        denied.contains(.allowExtensions)
    }

    /// Whether an administrator forbids per-certificate TLS exceptions.
    public var forbidsCertificateExceptions: Bool {
        denied.contains(.allowCertificateExceptions)
    }

    /// Returns `configuration` clamped so no setting violates an administrator-forced rule.
    public func clamp(_ configuration: Configuration) -> Configuration {
        var clamped = configuration
        if denied.contains(.allowSafeDownloadAutoOpen) {
            clamped.web.openSafeDownloads = false
        }
        if requiresHardenedWeb, clamped.web.hardening == .off {
            clamped.web.hardening = .noJIT
        }
        if requiresHTTPSUpgrade, clamped.web.httpsUpgrade == .off {
            clamped.web.httpsUpgrade = .fallback
        }
        if requiresAutomaticUpdates {
            clamped.updates.automatic = true
        }
        if let maxMinutes = maxVaultLockMinutes {
            if clamped.passwords.lockAfter <= 0 || clamped.passwords.lockAfter > maxMinutes {
                clamped.passwords.lockAfter = maxMinutes
            }
        }
        return clamped
    }

    private static func parseLockMinutes(_ value: Any) -> Double {
        if value is Bool { return 5.0 }
        if let number = value as? NSNumber {
            // Distinguish CFBoolean from real numbers so forced `false` fails closed to 5 minutes.
            if CFGetTypeID(number) == CFBooleanGetTypeID() { return 5.0 }
            let mins = number.doubleValue
            if mins > 0 && mins <= 60 { return mins }
            return 5.0
        }
        return 5.0
    }
}
