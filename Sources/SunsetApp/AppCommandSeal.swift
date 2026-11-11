import CryptoKit
import SunsetHost
import SunsetShell

/// The app's sealer: `CommandSeal` with the Keychain's key.
struct AppCommandSeal: CommandSealing {
    let seal: CommandSeal

    init(key: SymmetricKey) { seal = CommandSeal(key: key) }

    func seal(_ command: String) -> String { seal.seal(command) }
    func verifies(_ command: String, seal mark: String?) -> Bool { seal.verifies(command, seal: mark) }
}
