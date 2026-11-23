import Foundation
import Testing

@testable import SunsetWeb

/// Per-variant `WKWebsiteDataStore` identifiers (ADR-0125): deterministic per profile, distinct between default and
/// named profiles, and distinct from the profile's own UUID so bundled WebKit never collides with system WebKit stores.
struct VariantStoreTests {
    @Test func derivesDeterministicDistinctUUIDs() {
        let profileA = UUID()
        let profileB = UUID()
        let bundledDefault = VariantStore.bundledIdentifier(for: nil)
        let bundledA = VariantStore.bundledIdentifier(for: profileA)
        let bundledB = VariantStore.bundledIdentifier(for: profileB)
        #expect(bundledDefault == VariantStore.bundledIdentifier(for: nil))
        #expect(bundledA == VariantStore.bundledIdentifier(for: profileA))
        #expect(bundledA != profileA)
        #expect(bundledB != profileB)
        #expect(bundledDefault != bundledA && bundledA != bundledB && bundledDefault != bundledB)
    }
}
