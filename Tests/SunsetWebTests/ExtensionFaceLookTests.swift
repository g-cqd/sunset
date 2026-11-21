import Testing

@testable import SunsetWebModel

/// An extension unavailable here looks it: grey, faded, blending with the chrome; available, its own colours.
@Suite("How an extension's button looks")
struct ExtensionFaceLookTests {
    @Test func `available: its own colours; unavailable: grey, faded, blended`() {
        #expect(ExtensionFaceLook.of(available: true) == ExtensionFaceLook(saturation: 1, opacity: 1, blends: false))
        let faded = ExtensionFaceLook.of(available: false)
        #expect(faded.saturation == 0)
        #expect(faded.opacity <= 0.45 && faded.opacity >= 0.25, "faded, still findable")
        #expect(faded.blends)
    }
}
