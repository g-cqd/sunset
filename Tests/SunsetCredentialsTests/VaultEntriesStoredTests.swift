import Foundation
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetCredentials

/// Entries and the person's templates kept in a vault (roadmap 0092 A): each one sealed record under its id, read back
/// whole after the vault is opened again and unlocked; nothing while it is locked.
@MainActor
@Suite("Entries kept in a vault")
struct VaultEntriesStoredTests {
    private let cheap = MasterPassword.Cost(memoryKiB: 64, passes: 1, lanes: 1)

    @Test func `saved, then read back after the vault is opened again; removed; refused while locked`() throws {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "vault-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let place = folder.appending(path: "v.vault").path
        let (made, _) = try Vault.create(
            at: place,
            password: "pw",
            cost: cheap,
            runtime: time.runtime,
            locks: VaultLocks()
        )
        var login = EntryTemplate.login.makeEntry(title: "Example")
        login.set(try #require(login.field(named: "Password")?.id), "hunter2")
        let note = EntryTemplate.secureNote.makeEntry(title: "Note")
        let mine = EntryTemplate(
            name: "Locker",
            symbol: "lock",
            sections: [EntrySection(name: "Locker", fields: [EntryField(name: "Combination", kind: .concealed)])]
        )
        try made.save(login)
        try made.save(note)
        try made.save(mine)
        made.lock.lock(.byHand)
        let vault = try Vault.open(at: place, runtime: time.runtime, locks: VaultLocks())
        #expect(throws: Vault.Refused.self) { try vault.entries() }
        try vault.unlock(password: "pw")
        #expect(try vault.entries().sorted { $0.title < $1.title } == [login, note])
        #expect(try vault.templates() == [mine])
        try vault.remove(entry: note.id)
        #expect(try vault.entries() == [login])
    }
}
