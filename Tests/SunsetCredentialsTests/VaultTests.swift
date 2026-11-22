import Foundation
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetCredentials
@testable import SunsetStorage

/// A vault made, opened and unlocked (roadmap 0091 E's ground): made with a master password and a recovery code, shown
/// once; opened later, locked; unlocked by either factor to the same key; a wrong one refused; the factors kept in its
/// file, sealed, so that a changed slot refuses rather than opens. Touch ID needs the Secure Enclave of a signed app: not
/// here.
@MainActor
@Suite("A vault, made and unlocked")
struct VaultTests {
    /// A cost a test can afford; the app's is measured (`MasterPassword.Cost.standard`).
    private let cheap = MasterPassword.Cost(memoryKiB: 64, passes: 1, lanes: 1)

    private func path() -> String {
        FileManager.default.temporaryDirectory.appending(path: "vault-\(UUID().uuidString)/personal.vault").path
    }

    @Test func `made with a password and a recovery code; opened locked; either factor unlocks to the same key`() throws
    {
        let time = TestTime()
        let place = path()
        defer { try? FileManager.default.removeItem(atPath: (place as NSString).deletingLastPathComponent) }
        let (made, code) = try Vault.create(at: place, password: "correct horse", cost: cheap, runtime: time.runtime)
        #expect(!made.lock.isLocked, "made unlocked")
        let entry = UUID()
        try made.put(Data("a secret".utf8), as: entry)
        made.lock.lock(.byHand)
        let vault = try Vault.open(at: place, runtime: time.runtime)
        #expect(vault.lock.isLocked && vault.factors == [.password, .recoveryCode])
        #expect(throws: Vault.Refused.self) { try vault.unlock(password: "wrong horse") }
        try vault.unlock(password: "correct horse")
        #expect(try vault.record(entry) == Data("a secret".utf8))
        vault.lock.lock(.byHand)
        #expect(throws: Vault.Refused.self) { try vault.record(entry) }
        try vault.unlock(recoveryCode: code)
        #expect(try vault.record(entry) == Data("a secret".utf8))
    }

    @Test func `a vault unlocked joins every vault that locks at once`() throws {
        let time = TestTime()
        let place = path()
        defer { try? FileManager.default.removeItem(atPath: (place as NSString).deletingLastPathComponent) }
        let locks = VaultLocks()
        let (vault, _) = try Vault.create(at: place, password: "pw", cost: cheap, runtime: time.runtime, locks: locks)
        locks.lockAll(.screenLocked)
        #expect(vault.lock.isLocked && vault.lock.lockedBecause == .screenLocked)
    }

    @Test func `a factor's slot changed in the file refuses, never opens`() throws {
        let time = TestTime()
        let place = path()
        defer { try? FileManager.default.removeItem(atPath: (place as NSString).deletingLastPathComponent) }
        let (made, code) = try Vault.create(at: place, password: "pw", cost: cheap, runtime: time.runtime)
        // The password's slot given the recovery code's wrap: the password's key does not open it.
        var slots = try made.file.factorSlots()
        slots[0].wrapped = slots[1].wrapped
        try made.file.setFactorSlots(slots)
        let vault = try Vault.open(at: place, runtime: time.runtime)
        #expect(throws: Vault.Refused.self) { try vault.unlock(password: "pw") }
        try vault.unlock(recoveryCode: code)
        #expect(!vault.lock.isLocked)
    }
}
