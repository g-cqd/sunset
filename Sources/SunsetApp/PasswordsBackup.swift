import AppKit
import CoreImage.CIFilterBuiltins
import SunsetAppCore
import SunsetConfig
import SunsetCredentials
import SunsetRuntime
import SunsetStorage
import UniformTypeIdentifiers

/// Sealed `.svault` backup, restore, automatic quit backups, and printable emergency sheet (roadmap 0095 A & B).
@MainActor
enum PasswordsBackup {
    static let contentType = UTType(filenameExtension: VaultBackup.fileExtension) ?? .data
    private static let largest = 256 << 20

    /// Writes a sealed `.svault` backup to a user-chosen path (`0600`).
    static func backup(from model: PasswordsModel) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [contentType]
        panel.nameFieldStringValue = "Sunset Vault.\(VaultBackup.fileExtension)"
        panel.message =
            "Choose where to save a sealed .\(VaultBackup.fileExtension) backup. "
            + "It stays encrypted and opens on any Mac with your master password or recovery code."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try model.exportBackup(to: url)
            logVaultBackup("backup_exported", outcome: "ok")
            confirmReveal(
                title: "Vault backed up",
                detail: "The backup is sealed with your vault key and does not include this Mac's Touch ID factor.",
                url: url
            )
        } catch {
            logVaultBackup("backup_exported", outcome: "failed")
            say("Backup failed", "Sunset could not write the backup file to that folder.")
        }
    }

    /// Opens a `.svault` backup using its master password or recovery code and merges it into the unlocked vault.
    static func restore(into model: PasswordsModel) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [contentType, .data]
        panel.message = "Choose a sealed .\(VaultBackup.fileExtension) backup to restore into this vault."
        panel.prompt = "Open"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard size > 0, size <= largest, let data = try? Data(contentsOf: url) else {
            say("Cannot read backup", "The selected file could not be read or is too large.")
            return
        }
        let header: VaultBackup.Header
        do {
            header = try VaultBackup.inspect(data)
        } catch let failure {
            say("Not a valid Sunset backup", describe(failure))
            return
        }
        guard let secret = askSecret(for: header) else { return }
        let opened: VaultBackup.Contents
        do {
            if let code = try? RecoveryCode(typed: secret) {
                opened = try VaultBackup.open(data, recoveryCode: code)
            } else {
                opened = try VaultBackup.open(data, password: secret)
            }
        } catch let failure {
            say("Could not open backup", describe(failure))
            return
        }
        do {
            let summary = try model.restoreBackup(opened)
            logVaultBackup(
                "backup_restored",
                outcome: "ok",
                attributes: ["entries_added": String(summary.entriesAdded)]
            )
            say(
                "Backup restored",
                "\(summary.entriesAdded) entries added, \(summary.entriesUnchanged) already present, "
                    + "\(summary.templatesAdded) templates added."
            )
        } catch {
            logVaultBackup("backup_restored", outcome: "failed")
            say("Restore failed", "Make sure your vault is unlocked before restoring a backup.")
        }
    }

    /// Runs an automatic `.svault` backup on quit when `passwords.backupFolder` is configured and a vault exists.
    static func backupAtQuitIfConfigured() {
        let settings = AppConfiguration.shared.configuration.passwords
        let folder = settings.backupFolder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !folder.isEmpty else { return }
        let expanded = (folder as NSString).expandingTildeInPath
        let directory = URL(filePath: expanded, directoryHint: .isDirectory)
        let vaultPath = (StoragePlaces.current.directory as NSString).appendingPathComponent("Vaults/personal.vault")
        guard let file = try? VaultFile.open(at: vaultPath) else { return }
        _ = try? VaultBackupSchedule.run(file: file, into: directory, keep: Int(settings.backupKeep))
    }

    /// Generates a printable emergency sheet (vault recovery code + QR code) as a PDF or print dialog (roadmap 0095 B).
    static func printEmergencySheet(code: RecoveryCode, vaultName: String = "Personal Vault") {
        let view = EmergencySheetView(vaultName: vaultName, recoveryCode: code.text, qr: makeQR(code.text))
        let printInfo = NSPrintInfo.shared.copy() as? NSPrintInfo ?? NSPrintInfo()
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .fit
        let op = NSPrintOperation(view: view, printInfo: printInfo)
        op.showsPrintPanel = true
        op.showsProgressPanel = true
        op.run()
    }

    private static func logVaultBackup(_ event: String, outcome: String, attributes: [String: String] = [:]) {
        SunsetStore.shared.recordSecurityEvent(
            .vault(event),
            outcome: outcome,
            attributes: attributes,
            at: Runtime.live.now()
        )
    }

    private static func makeQR(_ text: String) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        let rep = NSCIImageRep(ciImage: scaled)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }

    private static func askSecret(for header: VaultBackup.Header) -> String? {
        let alert = NSAlert()
        alert.messageText = "Unlock backup (\(header.recordCount) sealed records)"
        alert.informativeText = "Enter the backup's master password or recovery code."
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        field.placeholderString = "Master password or recovery code"
        alert.accessoryView = field
        alert.addButton(withTitle: "Restore")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let value = field.stringValue
        return value.isEmpty ? nil : value
    }

    private static func describe(_ failure: VaultBackup.Failure) -> String {
        switch failure {
            case .notABackup: "The file is not a Sunset .\(VaultBackup.fileExtension) backup."
            case .unsupportedVersion(let version):
                "This backup uses format version \(version), which is newer than this Sunset understands."
            case .damaged: "The backup file is damaged or incomplete."
            case .noPortableFactors: "This vault has no portable unlock factor to put in a backup."
            case .wrongSecret: "That password or recovery code did not unlock this backup."
            case .writeFailed: "The backup file could not be written."
        }
    }

    private static func say(_ title: String, _ detail: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.runModal()
    }

    static func confirmReveal(title: String, detail: String, url: URL) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: "Done")
        alert.addButton(withTitle: "Show File in Finder")
        if alert.runModal() == .alertSecondButtonReturn {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
}
