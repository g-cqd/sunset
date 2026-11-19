import AppKit
import LocalAuthentication
import Observation
import SunsetRuntime
import SunsetShell
import SunsetStorage

/// What Settings show of what Sunset keeps (R12, roadmap 0030 step ST-6): the inventory of its folder, the website data's size,
/// FileVault's state, and the recovery code while it is shown.
@MainActor @Observable
final class StorageSettings {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    @ObservationIgnored var runtime = Runtime.live

    static let shared = StorageSettings()

    private(set) var inventory = StorageInventory()
    /// What WebKit keeps for the app's pages, outside Sunset's folder; nil until it is counted.
    private(set) var websiteBytes: Int?
    private(set) var fileVault = FileVaultState.unknown
    /// The recovery code, while it is shown: the key itself.
    private(set) var code: String?
    /// Why the code is not shown, when it was asked for.
    private(set) var codeProblem: String?
    @ObservationIgnored private var reading: Task<Void, Never>?

    var places: StoragePlaces {
        AppStorage.shared.places
    }
    /// The key is here: its code can be shown. False when the Keychain refused, or what is kept is sealed with another key.
    var hasKey: Bool {
        AppStorage.shared.key != nil
    }

    /// Reads the folder, the website data's size and FileVault's state again, off the main thread.
    func refresh() {
        reading?.cancel()
        let places = places
        let web = StorageInventory.websiteDataPaths(
            home: NSHomeDirectory(),
            bundle: Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
        )
        reading = runtime.task {
            let read =
                await runtime.detached(priority: .utility) {
                    (inventory: StorageInventory(places), web: StorageInventory.size(of: web))
                }
                .value
            let vault = await FileVaultState.read()
            guard !Task.isCancelled else { return }
            inventory = read.inventory
            websiteBytes = read.web
            fileVault = vault
        }
    }

    /// Shows the recovery code, once the Mac has confirmed who is there (Touch ID, else the password). A named setup (a test's)
    /// keeps its key in a plain file beside its other files, and is not asked.
    func showCode() async {
        codeProblem = nil
        guard let key = AppStorage.shared.key else { return }
        if places.isDefault {
            do {
                let reason = "show the recovery code of what Sunset keeps"
                guard try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) else {
                    return
                }
            } catch LAError.passcodeNotSet {
                // A Mac with no password protects nothing by asking: the code is shown.
            } catch LAError.userCancel, LAError.appCancel, LAError.systemCancel {
                return
            } catch {
                codeProblem = "The Mac did not confirm who is there, so the code is not shown."
                return
            }
        }
        code = key.recoveryCode
    }

    func hideCode() {
        code = nil
    }

    /// Puts the shown code on the clipboard, marked as a secret so that clipboard managers that follow the convention leave it.
    @discardableResult
    func copyCode() -> ActionFeedback {
        guard let code else { return .blocked("The code is hidden") }
        return Clipboard.copy(code, concealed: true, what: "Copied")
    }

    /// What entering a recovery code did.
    enum Entered {
        /// Kept: Sunset uses it from its next start.
        case kept
        /// It is the key this Mac already has.
        case same
        /// Another key is kept here: what it sealed would no longer open. Asked again with `replacing`.
        case differs
        case notACode
        case refused
    }

    func enter(code: String, replacing: Bool) -> Entered {
        let ring = StorageKeyring(vault: places.keyVault)
        do {
            let before = try ring.existing()
            let key = try ring.restore(code: code, replacing: replacing)
            return before?.identifier == key.identifier ? .same : .kept
        } catch {
            switch error {
                case .badCode: return .notACode
                case .keyExists: return .differs
                case .vault: return .refused
            }
        }
    }
}
