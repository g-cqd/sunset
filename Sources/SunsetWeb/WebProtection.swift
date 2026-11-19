import SunsetWebModel
import WebKit

/// The protections WebKit offers each navigation, as a page's settings ask (task t115, diary 2026-11-19-07): HTTPS first,
/// the hardened mode (macOS 26.4), Global Privacy Control (macOS 27; a private window by its own rule).
@MainActor
enum WebProtection {
    static func preferences(for settings: WebSettings) -> WKWebpagePreferences {
        let preferences = WKWebpagePreferences()
        switch settings.httpsUpgrade {
            case .off: preferences.preferredHTTPSNavigationPolicy = .keepAsRequested
            case .fallback: preferences.preferredHTTPSNavigationPolicy = .automaticFallbackToHTTP
            case .ask: preferences.preferredHTTPSNavigationPolicy = .userMediatedFallbackToHTTP
            case .only: preferences.preferredHTTPSNavigationPolicy = .errorOnFailure
        }
        if #available(macOS 26.4, *) {
            preferences.securityRestrictionMode = settings.hardening == .noJIT ? .maximizeCompatibility : .none
        }
        // Set only to send it: set false, WebKit gives pages `navigator.globalPrivacyControl` (false), which Safari does not
        // have (the inventory, 2026-11-20); left alone, the property is not there.
        if #available(macOS 27, *) {
            let control = settings.globalPrivacyControl
            if control == .always || (control == .privateWindows && settings.privacy != nil) {
                preferences.globalPrivacyControlEnabled = true
            }
        }
        return preferences
    }
}
