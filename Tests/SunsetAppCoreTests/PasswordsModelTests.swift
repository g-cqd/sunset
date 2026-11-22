import Foundation
import SunsetCredentials
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetAppCore

/// What the Library's Passwords section shows and does (roadmap 0091 E, ADR-0116): no vault, set it up; locked, unlock
/// it; unlocked, its entries, kept as they change; locked again, nothing of it left in the model.
@MainActor
@Suite("The Passwords section's model")
struct PasswordsModelTests {
    private let cheap = MasterPassword.Cost(memoryKiB: 64, passes: 1, lanes: 1)

    private func model(_ folder: URL, _ time: TestTime) -> PasswordsModel {
        PasswordsModel(
            path: folder.appending(path: "Vaults/personal.vault").path,
            cost: cheap,
            runtime: time.runtime,
            locks: VaultLocks()
        )
    }

    @Test func `no vault, set one up: the passwords must match; the code is shown once; unlocked after`() throws {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "pw-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let passwords = model(folder, time)
        #expect(passwords.state == .none)
        #expect(throws: PasswordsModel.Mismatch.self) { try passwords.create(password: "one", again: "two") }
        #expect(throws: PasswordsModel.Mismatch.self) { try passwords.create(password: "", again: "") }
        let code = try passwords.create(password: "correct horse", again: "correct horse")
        #expect(!code.text.isEmpty && passwords.state == .unlocked && passwords.entries.isEmpty)
    }

    @Test func `entries added from a template, kept, listed by title; locked, gone from the model; unlocked, back`()
        throws
    {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "pw-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let passwords = model(folder, time)
        _ = try passwords.create(password: "pw", again: "pw")
        let bank = try passwords.add(from: .login, title: "Bank")
        _ = try passwords.add(from: .card, title: "Amex")
        #expect(passwords.entries.map(\.title) == ["Amex", "Bank"])
        var changed = bank
        changed.title = "Bank (old)"
        try passwords.save(changed)
        #expect(passwords.entries.map(\.title) == ["Amex", "Bank (old)"])
        passwords.lock()
        #expect(passwords.state == .locked && passwords.entries.isEmpty)
        #expect(!passwords.unlock(password: "wrong"))
        #expect(passwords.unlock(password: "pw") && passwords.entries.count == 2)
        try passwords.remove(bank.id)
        #expect(passwords.entries.map(\.title) == ["Amex"])
    }

    @Test
    func `a vault that locks by itself (the screen locked) empties the model; a new model finds the vault locked`()
        throws
    {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "pw-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let locks = VaultLocks()
        let passwords = PasswordsModel(
            path: folder.appending(path: "Vaults/personal.vault").path,
            cost: cheap,
            runtime: time.runtime,
            locks: locks
        )
        _ = try passwords.create(password: "pw", again: "pw")
        _ = try passwords.add(from: .secureNote, title: "Note")
        locks.lockAll(.screenLocked)
        #expect(passwords.state == .locked && passwords.entries.isEmpty)
        #expect(model(folder, time).state == .locked)
    }

    @Test func `the sites never to save for: kept, read again on unlocking, none in memory while locked`() throws {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "pw-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let passwords = model(folder, time)
        _ = try passwords.create(password: "pw", again: "pw")
        try passwords.setNeverSave("example.com")
        #expect(passwords.neverSave == ["example.com"])
        passwords.lock()
        #expect(passwords.neverSave.isEmpty)
        #expect(passwords.unlock(password: "pw") && passwords.neverSave == ["example.com"])
    }
}
