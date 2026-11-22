import Foundation
import SunsetAppCore
import SunsetRuntime
import SunsetStorage

/// The person's vault (roadmap 0091 E): one, under Sunset's folder (`Vaults/personal.vault`), made only when the person
/// sets it up from the Library's Passwords section. Nothing is opened while `features.credentials` is off.
@MainActor
enum AppPasswords {
    static let model = PasswordsModel(
        path: (StoragePlaces.current.directory as NSString).appendingPathComponent("Vaults/personal.vault"),
        runtime: .live
    )
}
