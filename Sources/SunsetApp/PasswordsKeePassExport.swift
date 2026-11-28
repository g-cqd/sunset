import AppKit
import SunsetAppCore
import SunsetCredentials
import SunsetRuntime
import UniformTypeIdentifiers

/// The vault written as a KeePass database (KDBX 4), for KeePass, KeePassXC and the apps that read them: the owner says it
/// is them, gives the database a master password (twice), and chooses where it goes; a file only they can read.
@MainActor
enum PasswordsKeePassExport {
    static func run(from model: PasswordsModel) {
        Runtime.live.task { @MainActor in
            guard await AppPasswordFill.isOwner(reason: "export every entry from Passwords as a KeePass database")
            else {
                return
            }
            guard let password = askPassword() else { return }
            let panel = NSSavePanel()
            panel.allowedContentTypes = [UTType(filenameExtension: "kdbx") ?? .data]
            panel.nameFieldStringValue = "Sunset.kdbx"
            panel.message = "Choose where to write the database. It is encrypted with the password you just gave."
            guard panel.runModal() == .OK, let url = panel.url else { return }
            let entries = model.entries
            let now = Runtime.live.now()
            let written = await Runtime.live
                .detached(priority: .userInitiated) {
                    try? KeePassWriter.write(entries, password: password, now: now)
                }
                .value
            guard let written, (try? VaultBackup.writeOwnerOnly(written, to: url)) != nil else {
                return PasswordsImport.say("The database could not be written", "Choose another folder.")
            }
            PasswordsBackup.confirmReveal(
                title: entries.count == 1 ? "1 entry exported" : "\(entries.count) entries exported",
                detail: "KeePass and KeePassXC open it with the password you gave.",
                url: url
            )
        }
    }

    /// The database's master password, typed twice; nil when cancelled or when the two differ.
    private static func askPassword() -> String? {
        guard
            let first = PasswordsBackup.askSecret(
                title: "Password for the KeePass Database",
                detail: "The database is encrypted with it. Keep it safe: without it the file cannot be opened.",
                placeholder: "Master Password",
                action: "Continue"
            ),
            let again = PasswordsBackup.askSecret(
                title: "Enter the Password Again",
                detail: "To be sure it is the one you meant.",
                placeholder: "Master Password",
                action: "Export"
            )
        else { return nil }
        guard first == again else {
            PasswordsImport.say("The passwords differ", "Nothing was exported. Try again.")
            return nil
        }
        return first
    }
}
