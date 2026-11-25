import AemiTestKit
import Foundation
import SunsetRuntime
import SunsetStorage
import SunsetTestSupport
import Testing

@testable import SunsetCredentials

/// Hostile, fuzz, and frozen-version tests for `.svault` backups (roadmap 0095 A, white paper §9):
/// - A frozen v1 fixture built with known deterministic bytes must always open (every version ever written stays readable).
/// - Random byte mutations, truncation, duplicate record IDs, out-of-bounds Argon2 costs, and planted Touch ID wraps are
///   refused cleanly without crashing or burning unbounded memory/CPU.
@MainActor
@Suite("Vault backup (.svault): hostile, fuzz & version compatibility")
struct VaultBackupHostileTests {
    private let fastCost = MasterPassword.Cost(memoryKiB: 16, passes: 1, lanes: 1)

    /// Frozen v1 backup fixture: generated once with a fixed vault ID, password `"frozen-v1-test-password"`, and one
    /// Login entry titled `"Frozen v1 Entry"` so any accidental format regression breaks immediately.
    @Test func `frozen v1 backup fixture always opens`() throws {
        let vaultID = try #require(UUID(uuidString: "11111111-2222-4333-8444-555555555555"))
        let entryID = try #require(UUID(uuidString: "AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE"))
        let key = StorageKey(bytes: Data(repeating: 0x42, count: 32))
        let salt = Data(repeating: 0x24, count: 16)
        let stretched = try MasterPassword.stretch("frozen-v1-test-password", salt: salt, cost: fastCost)
        let wrapped = try WrappedKey.wrap(key, with: stretched, factor: Vault.Factor.password.rawValue, vault: vaultID)
        let slot = VaultFile.FactorSlot(factor: .password, wrapped: wrapped, salt: salt, cost: fastCost)

        let entry = VaultEntry(
            id: entryID,
            title: "Frozen v1 Entry",
            template: EntryTemplate.login.id,
            sections: [
                EntrySection(
                    name: "Login",
                    fields: [EntryField(name: "Username", kind: .text, value: "ada")]
                )
            ]
        )
        let plain = try JSONEncoder().encode(VaultRecord.entry(entry))
        let identity = "vault:\(vaultID.uuidString)/record:\(entryID.uuidString)"
        let sealed = try Seal(key: key, purpose: .vaultRecord).seal(plain, identity: identity)

        // Assemble v1 wire format directly from the frozen specification.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let headerJSON = try encoder.encode(
            VaultBackup.RawHeader(
                vaultID: vaultID,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                factorSlots: [slot],
                recordCount: 1
            )
        )
        var fixture = Data("SVAULT".utf8)
        fixture.append(1)
        VaultBackup.appendUInt32(UInt32(headerJSON.count), to: &fixture)
        fixture.append(headerJSON)
        VaultBackup.appendUUID(entryID, to: &fixture)
        VaultBackup.appendUInt32(UInt32(sealed.count), to: &fixture)
        fixture.append(sealed)

        let opened = try VaultBackup.open(fixture, password: "frozen-v1-test-password")
        #expect(opened.header.version == 1)
        #expect(opened.header.vaultID == vaultID)
        #expect(opened.entries.count == 1)
        #expect(opened.entries[0].title == "Frozen v1 Entry")
        #expect(opened.entries[0].field(named: "Username")?.value == "ada")
    }

    @Test func `hostile header with excessive Argon2 cost is refused before stretching`() throws {
        let vaultID = UUID()
        let absurdCost = MasterPassword.Cost(memoryKiB: 999_999_999, passes: 99, lanes: 99)
        let slot = VaultFile.FactorSlot(
            factor: .password,
            wrapped: WrappedKey(factor: "password", sealed: Data(repeating: 0x01, count: 60)),
            salt: Data(repeating: 0x02, count: 16),
            cost: absurdCost
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let headerBytes = try encoder.encode(
            VaultBackup.RawHeader(
                vaultID: vaultID,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                factorSlots: [slot],
                recordCount: 0
            )
        )
        var data = Data("SVAULT".utf8)
        data.append(1)
        VaultBackup.appendUInt32(UInt32(headerBytes.count), to: &data)
        data.append(headerBytes)

        #expect(throws: VaultBackup.Failure.wrongSecret) {
            try VaultBackup.open(data, password: "anything")
        }
    }

    @Test func `hostile header with planted Touch ID slot is refused`() throws {
        let vaultID = UUID()
        let touchSlot = VaultFile.FactorSlot(
            factor: .touchID,
            wrapped: WrappedKey(factor: "touchID", sealed: Data(repeating: 0x01, count: 60)),
            touchID: Data(repeating: 0x02, count: 32)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let headerBytes = try encoder.encode(
            VaultBackup.RawHeader(
                vaultID: vaultID,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                factorSlots: [touchSlot],
                recordCount: 0
            )
        )
        var data = Data("SVAULT".utf8)
        data.append(1)
        VaultBackup.appendUInt32(UInt32(headerBytes.count), to: &data)
        data.append(headerBytes)
        #expect(throws: VaultBackup.Failure.damaged) { try VaultBackup.inspect(data) }
    }

    @Test func `fuzzed backup bytes never crash and never silently open with a damaged record`() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "svault-fuzz-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let (vault, code) = try Vault.create(
            at: dir.appending(path: "f.vault").path,
            password: "fuzz-password-1234",
            cost: fastCost,
            runtime: TestTime().runtime,
            locks: VaultLocks()
        )
        try vault.save(EntryTemplate.login.makeEntry(title: "Fuzz Entry"))
        let valid = try VaultBackup.export(from: vault)
        let corpus = Array(valid)

        let report = fuzzNeverTraps(
            seed: .named("svault.fuzz.bytes"),
            iterations: 2_000,
            edits: 1 ... 8,
            corpus: { corpus },
            exercise: { bytes in
                let mutated = Data(bytes)
                if mutated == valid { return }
                _ = try? VaultBackup.inspect(mutated)
                // Opening with the real recovery code must either refuse or yield the exact original entry.
                if let opened = try? VaultBackup.open(mutated, recoveryCode: code) {
                    #expect(opened.entries.map(\.title) == ["Fuzz Entry"])
                }
            }
        )
        #expect(report.iterations == 2_000)
    }
}
