// Lists WebKit's feature flags whose key names credentials, payments or autofill, with their defaults (2026-11-19).
import WebKit

MainActor.assumeIsolated {
    let p = WKPreferences()
    let t = type(of: p) as AnyObject as? NSObject ?? NSObject()
    let features = t.value(forKey: "_features") as? [NSObject] ?? []
    let pattern =
        "Pay|Payment|WebAuthn|Credential|Password|AutoFill|Autofill|OTP|Digital|Identity|Passkey|SecureContext|Crypto"
    for f in features {
        let key = f.value(forKey: "key") as? String ?? ""
        guard key.range(of: pattern, options: .regularExpression) != nil else { continue }
        let on = p.perform(NSSelectorFromString("_isEnabledForFeature:"), with: f) != nil
        print(key, "|", f.value(forKey: "name") ?? "", "| on:", on, "| status:", f.value(forKey: "status") ?? "")
    }
}
