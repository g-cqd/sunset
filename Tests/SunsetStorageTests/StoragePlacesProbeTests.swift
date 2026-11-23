import Testing

@testable import SunsetStorage

/// A test copy that probes the keychain (ADR-0125: is the key readable after an engine switch?): `$SUNSET_PROBE_KEYCHAIN`
/// keeps the named setup's folder but its key in the keychain, under a name of its own, never the person's.
@Suite("A test copy that probes the keychain")
struct StoragePlacesProbeTests {
    @Test func `a named setup with the probe keeps its key in the keychain under the probe's name`() {
        let plain = StoragePlaces(environment: ["SUNSET_CONFIG": "/tmp/p/c.json"], home: "/h")
        #expect(plain.keyVault is FileKeyVault)
        let probe = StoragePlaces(
            environment: ["SUNSET_CONFIG": "/tmp/p/c.json", "SUNSET_PROBE_KEYCHAIN": "x1"],
            home: "/h",
            identifier: "studio.aemi.sunset"
        )
        #expect(probe.directory == "/tmp/p" && !probe.isDefault)
        #expect(probe.keyVault is MovingKeyVault)
        #expect(probe.keyService == "studio.aemi.sunset.probe-x1.storage-key")
        #expect(probe.commandSealService == "studio.aemi.sunset.probe-x1.command-seal")
    }

    @Test func `the probe is ignored for the person's own setup and for unsafe names`() {
        let own = StoragePlaces(
            environment: ["SUNSET_PROBE_KEYCHAIN": "x1"],
            home: "/h",
            identifier: "studio.aemi.sunset"
        )
        #expect(own.keyService == "studio.aemi.sunset.storage-key")
        let odd = StoragePlaces(
            environment: ["SUNSET_CONFIG": "/tmp/p/c.json", "SUNSET_PROBE_KEYCHAIN": "../x"],
            home: "/h"
        )
        #expect(odd.keyVault is FileKeyVault)
    }
}
