import Testing

@testable import SunsetConfig

/// Task t115: what WebKit offers each navigation and Sunset did not ask for (diary 2026-11-19-07). HTTPS first, falling back
/// to http with Not Secure shown, as Safari does; the hardened mode (no JIT) and Global Privacy Control are the person's.
@Suite("The web's protections: settings")
struct WebProtectionSettingsTests {
    @Test func `defaults: https first with a fallback, not hardened, privacy control in private windows only`() {
        let web = Configuration().web
        #expect(web.httpsUpgrade == .fallback)
        #expect(web.hardening == .off)
        #expect(web.globalPrivacyControl == .privateWindows)
    }

    @Test func `each is read; nonsense is an issue that keeps the default`() throws {
        let read = try ConfigurationParser.parse(
            #"{ "web": { "httpsUpgrade": "only", "hardening": "noJIT", "globalPrivacyControl": "always" } }"#
        )
        #expect(read.issues.isEmpty, "\(read.issues)")
        #expect(read.configuration.web.httpsUpgrade == .only)
        #expect(read.configuration.web.hardening == .noJIT)
        #expect(read.configuration.web.globalPrivacyControl == .always)
        let bad = try ConfigurationParser.parse(#"{ "web": { "httpsUpgrade": "sometimes" } }"#)
        #expect(bad.configuration.web.httpsUpgrade == .fallback && bad.issues.map(\.path) == ["web.httpsUpgrade"])
    }
}
