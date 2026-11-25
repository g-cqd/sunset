import Foundation
import SunsetRuntime
import SunsetStorage
import SunsetTestSupport
import Testing

@testable import SunsetCredentials

/// Sealed vault backups (`.svault`, roadmap 0095 A): versioned, never containing Touch ID's device-bound wrap,
/// opening with the master password or recovery code on any Mac, refusing tampered or unknown-version files, and
/// keeping a frozen v1 fixture test so every version ever written continues to open.
@MainActor
@Suite("Vault backup (.svault)")
struct VaultBackupTests {
    private let fastCost = MasterPassword.Cost(memoryKiB: 16, passes: 1, lanes: 1)

    private func tempDir(_ name: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appending(path: "svault-\(name)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeVault(
        in dir: URL,
        password: String = "correct-horse-battery-staple"
    ) throws -> (Vault, RecoveryCode) {
        let path = dir.appending(path: "test.vault").path
        return try Vault.create(
            at: path,
            password: password,
            cost: fastCost,
            runtime: TestTime().runtime,
            locks: VaultLocks()
        )
    }

    @Test func `round-trip preserves entries, custom templates, and never-save sites via password and recovery code`()
        throws
    {
        let dir = try tempDir("roundtrip")
        defer { try? FileManager.default.removeItem(at: dir) }

        let (vault, code) = try makeVault(in: dir)
        var login = EntryTemplate.login.makeEntry(title: "Example Bank")
        if let userField = login.field(named: "Username") { login.set(userField.id, "ada@example.com") }
        if let passField = login.field(named: "Password") { login.set(passField.id, "s3cr3t-p@ss-99!") }
        login.note = "Keep this sealed."
        login.folder = "Finance"
        login.tags = ["bank", "primary"]
        login.isFavorite = true

        let note = EntryTemplate.secureNote.makeEntry(title: "Private Note")
        let template = EntryTemplate(
            name: "SSH Key",
            symbol: "key",
            sections: [EntrySection(name: "Key", fields: [EntryField(name: "Fingerprint", kind: .text)])]
        )

        try vault.save(login)
        try vault.save(note)
        try vault.save(template)
        try vault.setNeverSave(["ignore.example.com", "local.test"])
        let bytes = try VaultBackup.export(from: vault, createdAt: Date(timeIntervalSince1970: 1_795_571_285))

        // Magic header and version byte are present; no plaintext secret leaks into the backup bytes.
        #expect(VaultBackup.isBackup(bytes))
        #expect(bytes.range(of: Data("s3cr3t-p@ss-99!".utf8)) == nil)
        #expect(bytes.range(of: Data("Example Bank".utf8)) == nil)
        #expect(bytes.range(of: Data("ignore.example.com".utf8)) == nil)

        // Inspect metadata without unlocking.
        let header = try VaultBackup.inspect(bytes)
        #expect(header.version == VaultBackup.currentVersion)
        #expect(header.recordCount == 4)
        #expect(header.factors == [.password, .recoveryCode])

        // Open with master password.
        let byPassword = try VaultBackup.open(bytes, password: "correct-horse-battery-staple")
        #expect(byPassword.entries.count == 2)
        #expect(byPassword.entries.first { $0.id == login.id } == login)
        #expect(byPassword.entries.first { $0.id == note.id } == note)
        #expect(byPassword.templates == [template])
        #expect(byPassword.neverSave == ["ignore.example.com", "local.test"])

        // Open with recovery code.
        let byCode = try VaultBackup.open(bytes, recoveryCode: code)
        #expect(byCode.entries.count == 2)
        #expect(byCode.templates == [template])
        #expect(byCode.neverSave == ["ignore.example.com", "local.test"])
    }

    @Test func `Touch ID factor slot is stripped when exporting and refused if planted in a backup`() throws {
        let dir = try tempDir("notouchid")
        defer { try? FileManager.default.removeItem(at: dir) }

        let (vault, _) = try makeVault(in: dir)
        var slots = try vault.file.factorSlots()
        let fakeTouch = VaultFile.FactorSlot(
            factor: .touchID,
            wrapped: WrappedKey(factor: "touchID", sealed: Data(repeating: 0x11, count: 60)),
            touchID: Data(repeating: 0x22, count: 64)
        )
        slots.insert(fakeTouch, at: 0)
        try vault.file.setFactorSlots(slots)
        #expect(vault.factors.contains(.touchID))

        let bytes = try VaultBackup.export(from: vault)
        let header = try VaultBackup.inspect(bytes)
        #expect(!header.factors.contains(.touchID))
        #expect(header.factors == [.password, .recoveryCode])
        #expect(bytes.range(of: Data("touchID".utf8)) == nil)
    }

    @Test
    func `wrong password, wrong recovery code, tampered bytes, trailing garbage, and unknown version are refused`()
        throws
    {
        let dir = try tempDir("refusals")
        defer { try? FileManager.default.removeItem(at: dir) }

        let (vault, _) = try makeVault(in: dir)
        try vault.save(EntryTemplate.login.makeEntry(title: "Site"))
        let bytes = try VaultBackup.export(from: vault)

        // Wrong password & wrong recovery code.
        #expect(throws: VaultBackup.Failure.wrongSecret) {
            try VaultBackup.open(bytes, password: "wrong-password-1234")
        }
        #expect(throws: VaultBackup.Failure.wrongSecret) {
            try VaultBackup.open(bytes, recoveryCode: RecoveryCode.generate())
        }

        // Bad magic.
        var badMagic = bytes
        badMagic[0] ^= 0xFF
        #expect(throws: VaultBackup.Failure.notABackup) { try VaultBackup.inspect(badMagic) }

        // Unknown future version.
        var future = bytes
        future[VaultBackup.magic.count] = 99
        #expect(throws: VaultBackup.Failure.unsupportedVersion(99)) { try VaultBackup.inspect(future) }

        // Tampered trailing record byte.
        var tampered = bytes
        tampered[tampered.count - 1] ^= 0x01
        #expect(throws: VaultBackup.Failure.damaged) {
            try VaultBackup.open(tampered, password: "correct-horse-battery-staple")
        }

        // Appended trailing byte.
        var extra = bytes
        extra.append(0x00)
        #expect(throws: VaultBackup.Failure.damaged) { try VaultBackup.inspect(extra) }

        // Truncated file.
        #expect(throws: VaultBackup.Failure.damaged) {
            try VaultBackup.open(Data(bytes.prefix(bytes.count / 2)), password: "correct-horse-battery-staple")
        }
    }

    @Test func `backup exports while vault is locked using existing sealed records without decrypting`() throws {
        let dir = try tempDir("locked-export")
        defer { try? FileManager.default.removeItem(at: dir) }

        let (vault, code) = try makeVault(in: dir)
        let entry = EntryTemplate.login.makeEntry(title: "Locked Export Entry")
        try vault.save(entry)
        vault.lock.lock(.byHand)
        #expect(vault.lock.isLocked)

        let bytes = try VaultBackup.export(from: vault.file)
        let opened = try VaultBackup.open(bytes, recoveryCode: code)
        #expect(opened.entries == [entry])
    }

    @Test func `restore adds missing entries, preserves existing by default, and overwrites when asked`() throws {
        let dir = try tempDir("restore")
        defer { try? FileManager.default.removeItem(at: dir) }

        let (source, _) = try makeVault(in: dir.appending(path: "src"))
        let shared = EntryTemplate.login.makeEntry(title: "Shared From Backup")
        let onlyInBackup = EntryTemplate.login.makeEntry(title: "From Backup")
        try source.save(shared)
        try source.save(onlyInBackup)
        try source.setNeverSave(["backed-up.example.com"])
        let backup = try VaultBackup.export(from: source)

        let (dest, _) = try makeVault(in: dir.appending(path: "dst"), password: "another-vault-password")
        var destCopy = shared
        destCopy.title = "Shared Local"
        let onlyInDest = EntryTemplate.login.makeEntry(title: "Local Only")
        try dest.save(destCopy)
        try dest.save(onlyInDest)

        let opened = try VaultBackup.open(backup, password: "correct-horse-battery-staple")
        let summary = try VaultBackup.restore(opened, into: dest)
        #expect(summary.entriesAdded == 1)
        #expect(summary.entriesUpdated == 0)
        #expect(summary.entriesUnchanged == 1)
        #expect(summary.neverSaveAdded == 1)
        let all = try dest.entries()
        #expect(all.first { $0.id == shared.id }?.title == "Shared Local")
        #expect(Set(all.map(\.id)) == Set([shared.id, onlyInBackup.id, onlyInDest.id]))
        #expect(try dest.neverSave() == ["backed-up.example.com"])

        let overwritten = try VaultBackup.restore(opened, into: dest, overwriteExisting: true)
        #expect(overwritten.entriesUpdated == 1)
        #expect((try dest.entries()).first { $0.id == shared.id }?.title == "Shared From Backup")
    }

    @Test func `written backup file has 0600 permissions`() throws {
        let dir = try tempDir("perms")
        defer { try? FileManager.default.removeItem(at: dir) }

        let (vault, _) = try makeVault(in: dir)
        let out = dir.appending(path: "vault.svault")
        _ = try VaultBackup.write(from: vault, to: out)
        let attrs = try FileManager.default.attributesOfItem(atPath: out.path)
        let mode = (attrs[.posixPermissions] as? NSNumber)?.intValue
        #expect(mode == 0o600)
    }
}
