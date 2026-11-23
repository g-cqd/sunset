import Foundation
import SunsetStorage

/// A keychain probe's cleanup (`StoragePlaces.probe`): started with `$SUNSET_PROBE_KEYCHAIN` and
/// `$SUNSET_PROBE_KEYCHAIN_ERASE`, the copy removes its probe key (only that: never the person's, whose names differ) and ends.
enum ProbeKeychainErase {
    static func runIfAsked() {
        let environment = ProcessInfo.processInfo.environment
        guard environment["SUNSET_PROBE_KEYCHAIN_ERASE"] != nil else { return }
        let places = StoragePlaces.current
        guard !places.isDefault, places.keyService.contains(".probe-") else {
            FileHandle.standardError.write(Data("Sunset: no probe keychain to erase\n".utf8))
            exit(64)
        }
        let existed = ((try? places.keyVault.read()) ?? nil) != nil
        let removed = (try? places.keyVault.remove()) != nil
        let said = "Sunset: probe key \(places.keyService) existed: \(existed), removed: \(removed)\n"
        FileHandle.standardError.write(Data(said.utf8))
        exit(removed ? 0 : 1)
    }
}
