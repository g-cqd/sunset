import AppKit
import SunsetAppCore
import SunsetCredentials
import SunsetRuntime
import UniformTypeIdentifiers

/// Logins from the CSV file a browser or a password manager exported (roadmap 0095 D): the person chooses the file, is told what it holds
/// and that it is in the clear, and confirms; the logins are kept in the vault and the file is left where it is, for the person to delete.
@MainActor
enum PasswordsImport {
    /// A file larger than this is not a list of logins.
    static let largest = 64 << 20

    static func run(into model: PasswordsModel) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText, .plainText]
        panel.message = "Choose the CSV file your browser or password manager exported."
        panel.prompt = "Read"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let text = read(url) else { return }
        let site = AppPasswordFill.site
        let imported: LoginImport
        do {
            imported = try LoginImport.read(text, site: site).leavingOut(held: model.entries, site: site)
        } catch {
            say(
                "This is not a file of logins",
                "It has no password column. Sunset reads the CSV that Apple Passwords, Chrome, Edge, Brave, Firefox, Bitwarden, 1Password and LastPass export."
            )
            return
        }
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
            + "\n\nThe file holds passwords in the clear. Sunset leaves it where it is: delete it when you are done."
        ask.addButton(withTitle: "Add")
        ask.addButton(withTitle: "Cancel")
        guard ask.runModal() == .alertFirstButtonReturn else { return }
        do {
            let kept = try model.importLogins(imported.entries)
            let done = NSAlert()
            done.messageText = kept == 1 ? "1 login added" : "\(kept) logins added"
            done.informativeText =
                "The file is still where it was, with every password in the clear. Delete it when you are done."
            done.addButton(withTitle: "Done")
            done.addButton(withTitle: "Show File in Finder")
            if done.runModal() == .alertSecondButtonReturn { NSWorkspace.shared.activateFileViewerSelecting([url]) }
        } catch {
            say(
                "The logins were not all added",
                "The vault stopped them: \(model.entries.count) entries are in it now. Nothing was removed."
            )
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
}
