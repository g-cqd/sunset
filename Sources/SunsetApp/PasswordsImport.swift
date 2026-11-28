import AppKit
import SunsetAppCore
import SunsetCredentials
import SunsetRuntime
import UniformTypeIdentifiers

/// Logins from the CSV file a browser or a password manager exported, and out to one (roadmap 0095 D). In: the person chooses the file, is told
/// what it holds and that it is in the clear, and confirms; the logins are kept in the vault and the file is left where it is, for the person
/// to delete. Out: warned, the person says it is them (Touch ID, else the Mac's password), chooses where; a file only they can read.
@MainActor
enum PasswordsImport {
    /// A file larger than this is not a list of logins.
    static let largest = 64 << 20

    static func run(into model: PasswordsModel) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes =
            [.commaSeparatedText, .plainText, .json]
            + ["2fas", "kdbx", "1pux"]
            .compactMap {
                UTType(filenameExtension: $0)
            }
        panel.message =
            "Choose the file your browser, password manager, or authenticator exported: CSV, Bitwarden, Aegis, 2FAS, or "
            + "andOTP JSON, a 1Password export (.1pux), or a KeePass database (.kdbx)."
        panel.prompt = "Read"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let data = try? Data(contentsOf: url, options: .mappedIfSafe), LoginImport.isKeePass(data) {
            Runtime.live.task { @MainActor in
                guard let imported = await PasswordsKeePassImport.read(data, against: model.entries) else { return }
                add(imported, from: url, into: model, inTheClear: false)
            }
            return
        }
        if let data = try? Data(contentsOf: url, options: .mappedIfSafe), LoginImport.isOnePasswordExport(data) {
            let site: @Sendable (String) -> String? = { AppPasswordFill.site($0) }
            do throws(LoginImport.Failure) {
                let read = try LoginImport.readOnePassword(data, site: site).leavingOut(held: model.entries, site: site)
                add(read, from: url, into: model, inTheClear: true)
            } catch {
                say("This 1Password export could not be read", "It may be damaged. Export it again from 1Password.")
            }
            return
        }
        guard let text = read(url) else { return }
        guard let imported = decodeImport(text, against: model.entries) else { return }
        add(imported, from: url, into: model, inTheClear: true)
    }

    /// The person told what `imported` holds, and asked; the entries kept. A file in the clear is said to be one.
    private static func add(_ imported: LoginImport, from url: URL, into model: PasswordsModel, inTheClear: Bool) {
        guard !imported.entries.isEmpty else {
            say(
                "Nothing to add",
                imported.report.dropFirst().joined(separator: "\n")
                    + (imported.report.count > 1 ? "" : "The file has no login.")
            )
            return
        }
        let ask = NSAlert()
        ask.messageText = "Add the logins from \(imported.sourceName)?"
        ask.informativeText =
            imported.report.joined(separator: "\n")
            + (inTheClear
                ? "\n\nThe file holds passwords in the clear. Sunset leaves it where it is: delete it when you are done."
                : "")
        ask.addButton(withTitle: "Add")
        ask.addButton(withTitle: "Cancel")
        guard ask.runModal() == .alertFirstButtonReturn else { return }
        do {
            let kept = try model.importLogins(imported.entries)
            guard inTheClear else {
                return say(kept == 1 ? "1 entry added" : "\(kept) entries added", "The database is left as it was.")
            }
            PasswordsBackup.confirmReveal(
                title: kept == 1 ? "1 login added" : "\(kept) logins added",
                detail:
                    "The file is still where it was, with every password in the clear. Delete it when you are done.",
                url: url
            )
        } catch {
            say(
                "The logins were not all added",
                "The vault stopped them: \(model.entries.count) entries are in it now. Nothing was removed."
            )
        }
    }

    private static func decodeImport(_ text: String, against held: [VaultEntry]) -> LoginImport? {
        let site = AppPasswordFill.site
        do throws(LoginImport.Failure) {
            if LoginImport.isPasswordProtectedBitwarden(text) {
                guard
                    let password = PasswordsBackup.askSecret(
                        title: "Unlock Encrypted Bitwarden Export",
                        detail: "Enter the password that protects this Bitwarden JSON export.",
                        placeholder: "Export Password",
                        action: "Decrypt"
                    )
                else { return nil }
                return try LoginImport.readEncryptedBitwarden(text, password: password, site: site)
                    .leavingOut(held: held, site: site)
            }
            return try LoginImport.readFile(text, site: site).leavingOut(held: held, site: site)
        } catch {
            say(error.words.title, error.words.detail)
            return nil
        }
    }

    private static func read(_ url: URL) -> String? {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard size <= largest else {
            say("This file is too large", "A list of logins is far smaller than \(largest >> 20) MiB.")
            return nil
        }
        guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else {
            say("The file could not be read", "It is not UTF-8 text. Export it again as CSV.")
            return nil
        }
        return text
    }

    private static func say(_ message: String, _ detail: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
    }

    /// Every login of the vault written to a file the person chooses, after a warning and the owner's word.
    static func export(from model: PasswordsModel) {
        let ask = NSAlert()
        ask.alertStyle = .warning
        ask.messageText = "Export every login?"
        ask.informativeText =
            "The file holds every password in the clear: anyone who can read it can sign in as you. Keep it only as long as you need it, "
            + "never in a synced or shared folder, and do not open it in a spreadsheet. Delete it when you are done."
        ask.addButton(withTitle: "Cancel")
        ask.addButton(withTitle: "Export…")
        guard ask.runModal() == .alertSecondButtonReturn else { return }
        Runtime.live.task { @MainActor in
            guard await AppPasswordFill.isOwner(reason: "export every login from Passwords, in the clear") else {
                return
            }
            let result = LoginExport.csv(of: model.entries)
            guard result.exported > 0 else {
                say("Nothing to export", "The vault has no login. Cards and notes are not exported.")
                return
            }
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.commaSeparatedText]
            panel.nameFieldStringValue = "Sunset Logins.csv"
            panel.message = "Choose where to write the file. It holds every password in the clear."
            guard panel.runModal() == .OK, let url = panel.url else { return }
            // Made readable by its owner only, from the start: not written and then restricted.
            let made = FileManager.default.createFile(
                atPath: url.path,
                contents: Data(result.text.utf8),
                attributes: [.posixPermissions: 0o600]
            )
            guard made else { return say("The file could not be written", "Choose another folder.") }
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            PasswordsBackup.confirmReveal(
                title: result.exported == 1 ? "1 login exported" : "\(result.exported) logins exported",
                detail: (result.skipped == 0
                    ? "" : "\(result.skipped) cards, notes or other entries are not logins and were left out.\n\n")
                    + "The file has every password in the clear. Delete it when you are done.",
                url: url
            )
        }
    }
}
