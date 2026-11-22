import Testing

@testable import SunsetStorage

/// A variant (a bundle identifier `studio.aemi.sunset.<name>`, not `.dev`) is another app: its own folder, its own
/// Keychain items.
@Suite("A variant of Sunset keeps its own") struct StoragePlacesVariantTests {
    @Test func `Sunset Lab has its folder and its keys, the person's setup none of them`() {
        let lab = StoragePlaces(environment: [:], home: "/Users/a", identifier: "studio.aemi.sunset.lab")
        #expect(lab.directory == "/Users/a/Library/Application Support/Sunset Lab")
        #expect(lab.keyService == "studio.aemi.sunset.lab.storage-key")
        #expect(lab.commandSealService == "studio.aemi.sunset.lab.command-seal")
        #expect(lab.variant == "lab" && lab.isDefault)
        let own = StoragePlaces(environment: [:], home: "/Users/a", identifier: "studio.aemi.sunset")
        #expect(own.directory == "/Users/a/Library/Application Support/Sunset" && own.variant == nil)
        let dev = StoragePlaces(environment: [:], home: "/Users/a", identifier: "studio.aemi.sunset.dev")
        #expect(
            dev.directory == "/Users/a/Library/Application Support/Sunset Dev"
                && dev.keyService == "studio.aemi.sunset.dev.storage-key"
        )
    }
}
