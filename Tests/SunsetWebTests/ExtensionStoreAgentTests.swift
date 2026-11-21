import Testing

@testable import SunsetWebModel

/// The owner, 2026-11-21: installing from a store only worked when Sunset was set to show Chrome; it should always work. Each
/// store is shown the browser it serves.
@Suite("The browser an extension store is shown")
struct ExtensionStoreAgentTests {
    @Test func `each store sees its browser; other sites are left to the person's settings`() {
        #expect(ExtensionStoreLink.storeAgent(forHost: "chromewebstore.google.com") == .chrome)
        #expect(ExtensionStoreLink.storeAgent(forHost: "chrome.google.com") == .chrome)
        #expect(ExtensionStoreLink.storeAgent(forHost: "addons.mozilla.org") == .firefox)
        #expect(ExtensionStoreLink.storeAgent(forHost: "google.com") == nil)
        #expect(ExtensionStoreLink.storeAgent(forHost: "evil-chromewebstore.google.com.example") == nil)
        #expect(ExtensionStoreLink.storeAgent(forHost: nil) == nil)
    }
}
