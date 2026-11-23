import Foundation
import SunsetAppCore
import SunsetConfig
import SunsetRuntime
import SunsetStorage

/// The person's vault (roadmap 0091 E): one, under Sunset's folder (`Vaults/personal.vault`), made only when the person
/// sets it up from the Library's Passwords section. Nothing is opened while `features.credentials` is off.
@MainActor
enum AppPasswords {
    static let model: PasswordsModel = {
        let made = PasswordsModel(
            path: (StoragePlaces.current.directory as NSString).appendingPathComponent("Vaults/personal.vault"),
            runtime: .live
        )
        created = true
        apply(settings, to: made)
        return made
    }()

    /// `passwords.*`, given by the configuration; applied to the model once it exists (it is not made for them: nothing
    /// of the vault is opened while `features.credentials` is off).
    static var settings = Configuration.Passwords() {
        didSet {
            if created { apply(settings, to: model) }
        }
    }

    /// Whether `model` was made.
    private static var created = false

    private static func apply(_ settings: Configuration.Passwords, to model: PasswordsModel) {
        model.lockAfter(minutes: settings.lockAfter)
        model.lockWhen = LockWhen(leavingTab: settings.lockOnLeavingTab, windowInactive: settings.lockOnWindowBlur)
    }
}
