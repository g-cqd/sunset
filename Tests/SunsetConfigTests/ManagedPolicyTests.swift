import Foundation
import Testing

@testable import SunsetConfig

/// Managed MDM preferences (`ManagedPolicy`, R-OPS-2): only administrator-forced keys apply, and invalid forced values
/// fail closed.
@Suite("Managed preferences policy (MDM)")
struct ManagedPolicyTests {
    @Test func `clamps configuration to forced administrator rules and fails closed on wrong types`() {
        var config = Configuration()
        config.web.openSafeDownloads = true
        config.web.hardening = .off
        config.web.httpsUpgrade = .off
        config.updates.automatic = false
        config.passwords.lockAfter = 0

        let policy = ManagedPolicy { key in
            switch key {
                case ManagedPolicy.Key.allowExtensions.rawValue: false
                case ManagedPolicy.Key.allowCertificateExceptions.rawValue: "invalid-type"
                case ManagedPolicy.Key.requireHardenedWeb.rawValue: true
                case ManagedPolicy.Key.requireHTTPSUpgrade.rawValue: true
                case ManagedPolicy.Key.allowSafeDownloadAutoOpen.rawValue: false
                case ManagedPolicy.Key.requireAutomaticUpdates.rawValue: true
                case ManagedPolicy.Key.maxVaultLockMinutes.rawValue: 15
                default: nil
            }
        }

        #expect(policy.forbidsExtensions)
        #expect(policy.forbidsCertificateExceptions, "wrong type on Allow* must fail closed")

        let clamped = policy.clamp(config)
        #expect(!clamped.web.openSafeDownloads)
        #expect(clamped.web.hardening == .noJIT)
        #expect(clamped.web.httpsUpgrade == .fallback)
        #expect(clamped.updates.automatic)
        #expect(clamped.passwords.lockAfter == 15)
    }

    @Test func `unforced policy leaves configuration untouched`() {
        var config = Configuration()
        config.web.openSafeDownloads = true
        config.passwords.lockAfter = 30
        let empty = ManagedPolicy { _ in nil }
        #expect(!empty.forbidsExtensions)
        #expect(!empty.forbidsCertificateExceptions)
        #expect(empty.clamp(config) == config)
    }
}
