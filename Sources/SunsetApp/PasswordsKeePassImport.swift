import AppKit
import SunsetCredentials
import SunsetRuntime
import UniformTypeIdentifiers

/// A KeePass database read for the import (`PasswordsImport`): its password asked; refused, the person may try another,
/// or give the key file it also needs. Derived off the main thread: Argon2 takes a moment.
@MainActor
enum PasswordsKeePassImport {
    static func read(_ data: Data, against held: [VaultEntry]) async -> LoginImport? {
        let site: @Sendable (String) -> String? = { AppPasswordFill.site($0) }
        var keyFile: Data?
        while true {
            guard
                let password = PasswordsBackup.askSecret(
                    title: "Open KeePass Database",
                    detail: keyFile == nil
                        ? "Enter the database's master password."
                        : "Enter the master password, with the key file chosen.",
                    placeholder: "Master Password",
                    action: "Open"
                )
            else { return nil }
            let key = keyFile
            let now = Runtime.live.now()
            let outcome = await Runtime.live
                .detached(priority: .userInitiated) {
                    Result { () throws(LoginImport.KeePassFailure) -> LoginImport in
                        try LoginImport.readKeePass(data, password: password, keyFile: key, now: now, site: site)
                    }
                }
                .value
            switch outcome {
                case .success(let read): return read.leavingOut(held: held, site: site)
                case .failure(.wrongKey):
                    switch askAgain(hasKeyFile: keyFile != nil) {
                        case .tryAgain: continue
                        case .keyFile(let chosen): keyFile = chosen
                        case .cancel: return nil
                    }
                case .failure(.oldVersion):
                    PasswordsImport.say(
                        "This database is in an older format",
                        "Sunset reads KDBX 4. Open it in KeePassXC or KeePass and save it again: it is then KDBX 4."
                    )
                    return nil
                case .failure(.unreadable):
                    PasswordsImport.say(
                        "This database could not be read",
                        "It may be damaged, or use a cipher or key derivation KeePass does not. Nothing was imported."
                    )
                    return nil
            }
        }
    }

    private enum Again {
        case tryAgain
        case keyFile(Data)
        case cancel
    }

    /// The key was wrong: another password, a key file, or nothing.
    private static func askAgain(hasKeyFile: Bool) -> Again {
        let alert = NSAlert()
        alert.messageText = "The database did not open"
        alert.informativeText =
            hasKeyFile
            ? "The master password or the key file is not this database's."
            : "The master password is not this database's, or it also needs a key file."
        alert.addButton(withTitle: "Try Again")
        alert.addButton(withTitle: "Choose Key File\u{2026}")
        alert.addButton(withTitle: "Cancel")
        switch alert.runModal() {
            case .alertFirstButtonReturn: return .tryAgain
            case .alertSecondButtonReturn:
                let panel = NSOpenPanel()
                panel.message = "Choose the key file this database needs."
                panel.prompt = "Use"
                guard panel.runModal() == .OK, let url = panel.url,
                    let data = try? Data(contentsOf: url), data.count <= 1 << 20
                else { return .cancel }
                return .keyFile(data)
            default: return .cancel
        }
    }
}
