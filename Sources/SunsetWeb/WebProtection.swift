import SunsetWebModel
import WebKit

/// The protections WebKit offers each navigation, as a page's settings ask (task t115, diary 2026-11-19-07): HTTPS first,
/// the hardened mode (macOS 26.4), Global Privacy Control (macOS 27; a private window by its own rule).
///
/// The SDKs disagree on both newer properties: the macOS 26 SDK of CI's runners marks `securityRestrictionMode` 26.5 (the
/// 27 SDK says 26.4), and has no `globalPrivacyControlEnabled` at all. Hence 26.5, and Global Privacy Control set by its key
/// where the running WebKit has it, so that one source builds with either SDK.
@MainActor
enum WebProtection {
    static func preferences(for settings: WebSettings, host: String? = nil, allowedOverHTTP: Set<String> = [])
        -> WKWebpagePreferences
    {
        let preferences = WKWebpagePreferences()
        switch settings.httpsUpgrade.policy(host: host, allowedOverHTTP: allowedOverHTTP) {
            case .keepAsRequested: preferences.preferredHTTPSNavigationPolicy = .keepAsRequested
            case .fallBackQuietly: preferences.preferredHTTPSNavigationPolicy = .automaticFallbackToHTTP
            case .failVisibly: preferences.preferredHTTPSNavigationPolicy = .errorOnFailure
        }
        if #available(macOS 26.5, *) {
            preferences.securityRestrictionMode = settings.hardening == .noJIT ? .maximizeCompatibility : .none
        }
        // Set only to send it: set false, WebKit gives pages `navigator.globalPrivacyControl` (false), which Safari does not
        // have (the inventory, 2026-11-20); left alone, the property is not there.
        let control = settings.globalPrivacyControl
        if control == .always || (control == .privateWindows && settings.privacy != nil),
            preferences.responds(to: NSSelectorFromString("setGlobalPrivacyControlEnabled:"))
        {
            preferences.setValue(true, forKey: "globalPrivacyControlEnabled")
        }
        return preferences
    }
}
