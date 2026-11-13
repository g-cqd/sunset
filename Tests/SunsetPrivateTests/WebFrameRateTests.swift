import SunsetPrivate
import Testing
import WebKit

@MainActor
struct WebFrameRateTests {
    /// WebKit's state for the feature, read the way it is set.
    private func capped(_ preferences: WKPreferences) throws -> Bool {
        let features = try #require(WKPreferences.value(forKey: "_features") as? [NSObject])
        let feature = try #require(
            features.first { ($0.value(forKey: "key") as? String) == "PreferPageRenderingUpdatesNear60FPSEnabled" }
        )
        typealias Getter = @convention(c) (NSObject, Selector, NSObject) -> Bool
        let selector = NSSelectorFromString("_isEnabledForFeature:")
        return unsafeBitCast(preferences.method(for: selector), to: Getter.self)(preferences, selector, feature)
    }

    @Test func `full rate turns WebKit's near-60 fps preference off, and back on`() throws {
        let preferences = WKPreferences()
        #expect(try capped(preferences))
        WebFrameRate.set(fullRate: true, on: preferences)
        #expect(try !capped(preferences))
        WebFrameRate.set(fullRate: false, on: preferences)
        #expect(try capped(preferences))
    }
}
