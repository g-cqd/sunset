import Foundation
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetCredentials

/// Automatic vault backups (roadmap 0095 B): writes timestamped `.svault` files to a chosen folder, keeps only the
/// newest `keep` backups, never deletes unrelated files, and skips writing when the folder is unset or disabled.
@MainActor
@Suite("Automatic vault backups")
struct VaultBackupScheduleTests {
    private let fastCost = MasterPassword.Cost(memoryKiB: 16, passes: 1, lanes: 1)

    private func tempDir(_ name: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appending(path: "svault-sched-\(name)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func `writes timestamped .svault files, prunes oldest past keep limit, and leaves unrelated files alone`()
        throws
    {
        let dir = try tempDir("rotate")
        defer { try? FileManager.default.removeItem(at: dir) }

        let (vault, code) = try Vault.create(
            at: dir.appending(path: "personal.vault").path,
            password: "correct-horse-battery-staple",
            cost: fastCost,
            runtime: TestTime().runtime,
            locks: VaultLocks()
        )
        let entry = EntryTemplate.login.makeEntry(title: "Saved Entry")
        try vault.save(entry)

        let backupDir = dir.appending(path: "backups")
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        let unrelated = backupDir.appending(path: "readme.txt")
        try Data("keep me".utf8).write(to: unrelated)

        var written: [URL] = []
        for step in 0 ..< 5 {
            let when = Date(timeIntervalSince1970: 1_795_571_000 + Double(step * 60))
            let url = try VaultBackupSchedule.run(file: vault.file, into: backupDir, keep: 3, now: when)
            written.append(url)
        }

        let remaining = VaultBackupSchedule.list(in: backupDir)
        #expect(remaining.count == 3)
        #expect(remaining.map(\.lastPathComponent) == written.suffix(3).map(\.lastPathComponent))
        #expect(FileManager.default.fileExists(atPath: unrelated.path))

        // Newest backup opens with the recovery code and holds the saved entry.
        let newest = try #require(remaining.last)
        let opened = try VaultBackup.open(try Data(contentsOf: newest), recoveryCode: code)
        #expect(opened.entries == [entry])
    }

    @Test func `keep of 1 keeps only the latest backup; non-positive keep is clamped to 1`() throws {
        let dir = try tempDir("clamp")
        defer { try? FileManager.default.removeItem(at: dir) }

        let (vault, _) = try Vault.create(
            at: dir.appending(path: "personal.vault").path,
            password: "correct-horse-battery-staple",
            cost: fastCost,
            runtime: TestTime().runtime,
            locks: VaultLocks()
        )
        let backupDir = dir.appending(path: "backups")
        _ = try VaultBackupSchedule.run(
            file: vault.file,
            into: backupDir,
            keep: 0,
            now: Date(timeIntervalSince1970: 1_795_571_000)
        )
        _ = try VaultBackupSchedule.run(
            file: vault.file,
            into: backupDir,
            keep: 0,
            now: Date(timeIntervalSince1970: 1_795_571_120)
        )
        #expect(VaultBackupSchedule.list(in: backupDir).count == 1)
    }
}
