// WebKit's defaults for safety features Sunset does not set (2026-11-19): the fraudulent-site warning (Safe Browsing through
// Apple's service) and the HTTPS upgrade policy.
import WebKit

MainActor.assumeIsolated {
    let configuration = WKWebViewConfiguration()
    print("isFraudulentWebsiteWarningEnabled:", configuration.preferences.isFraudulentWebsiteWarningEnabled)
    let policy = configuration.defaultWebpagePreferences.preferredHTTPSNavigationPolicy
    print("preferredHTTPSNavigationPolicy:", policy.rawValue, policy == .keepAsRequested ? "(keepAsRequested)" : "")
}
