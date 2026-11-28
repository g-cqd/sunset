public import Foundation

/// A KeePass database (KDBX 4) read into the vault (roadmap 0095 E, t104): each entry a login, or a secure note when it has
/// neither username, password nor address; its other strings as custom fields (hidden when KeePass protects them), its
/// group as the folder, its tags, its attachments, the earlier values of its password as the field's history, its
/// one-time code (KeePassXC's `otp`, KeePass's `TimeOtp-Secret-Base32`, the older `TOTP Seed`). Entries in the recycle bin
/// are left out and counted.
extension LoginImport {
    /// Whether `data` is a KeePass database.
    public static func isKeePass(_ data: Data) -> Bool {
        KeePassFile.isKeePass(data)
    }

    /// Why a KeePass database is not read.
    public enum KeePassFailure: Error, Equatable, Sendable {
        /// The password, or the key file, is not this database's (or it needs a key file).
        case wrongKey
        /// A KDBX 3 or older: saved again by KeePass 2 or KeePassXC, it is KDBX 4.
        case oldVersion
        /// A cipher, a key derivation or a parameter KeePass does not use; or the file is damaged.
        case unreadable
    }

    public static func readKeePass(
        _ data: Data,
        password: String,
        keyFile: Data? = nil,
        now: Date,
        site: (String) -> String?
    ) throws(KeePassFailure) -> Self {
        let contents: KeePassFile.Contents
        do {
            contents = try KeePassFile.open(data, password: password, keyFile: keyFile)
        } catch {
            switch error {
                case .wrongKey: throw .wrongKey
                case .unsupportedVersion: throw .oldVersion
                default: throw .unreadable
            }
        }
        guard let read = KeePassXML.entries(of: contents) else { throw .unreadable }
        var entries: [VaultEntry] = []
        var skipped: [Skipped] = []
        var warnings: [Warning] = []
        for (offset, item) in read.enumerated() {
            let number = offset + 1
            guard !item.deleted else {
                skipped.append(Skipped(row: number, reason: .deleted))
                continue
            }
            var made = KeePassEntry(item, attachments: contents.attachments, now: now, site: site)
            if made.unreadableCode { warnings.append(Warning(row: number, reason: .unreadableCode)) }
            made.entry.attachments = made.entry.attachments?.isEmpty == true ? nil : made.entry.attachments
            entries.append(made.entry)
        }
        return Self(source: .keePass, entries: entries, skipped: skipped, warnings: warnings, duplicates: 0)
    }
}
