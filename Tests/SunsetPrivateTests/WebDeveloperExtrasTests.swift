import Testing
import WebKit

@testable import SunsetPrivate

/// The owner, 2026-11-18: no Inspect Element in a page's menu, the setting on. WebKit has `_developerExtrasEnabled` and
/// `_setDeveloperExtrasEnabled:`, not `developerExtrasEnabled`: the check for the getter without its underscore failed, and
/// the preference was never set (probed: `responds(to:)` false for it, true for the underscored ones).
@MainActor
@Suite("WebKit's developer extras") struct WebDeveloperExtrasTests {
    @Test func `turned on and off, as the setting says`() {
        let preferences = WKPreferences()
        WebDeveloperExtras.set(true, on: preferences)
        #expect(preferences.value(forKey: "developerExtrasEnabled") as? Bool == true)
        WebDeveloperExtras.set(false, on: preferences)
        #expect(preferences.value(forKey: "developerExtrasEnabled") as? Bool == false)
    }
}
