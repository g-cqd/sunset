import Foundation
import SunsetCredentials
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetAppCore

/// The owner (n138, then: "the saving should be automatic … react to recent changes or loss of focus"): an edit the page
/// notes is kept when the vault locks (by hand, idle, any reason) and when Sunset loses focus, before the key is gone.
@MainActor
@Suite("Edits kept before the vault locks")
struct PasswordsPendingTests {
    private func unlocked(_ folder: URL, _ time: TestTime) async throws -> PasswordsModel {
        let model = PasswordsModel(
            path: folder.appending(path: "Vaults/personal.vault").path,
            cost: MasterPassword.Cost(memoryKiB: 64, passes: 1, lanes: 1),
            runtime: time.runtime,
            locks: VaultLocks()
        )
        let mark = time.mark()
        _ = try model.create(password: "correct horse battery", again: "correct horse battery")
        try await time.waited(since: mark)
        return model
    }

    @Test(arguments: [false, true])
    func `an edit noted and not yet kept is kept when the vault locks`(byIdle: Bool) async throws {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "pw-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let passwords = try await unlocked(folder, time)
        var card = try passwords.add(from: .card, title: "")
        card.title = "Visa"
        passwords.noteEdit(card)
        if byIdle {
            try await time.passToEnd(.seconds(600))
            #expect(passwords.state == .locked)
        } else {
            passwords.lock()
        }
        #expect(passwords.unlock(password: "correct horse battery"))
        #expect(passwords.entries.map(\.title) == ["Visa"])
    }

    @Test func `noted edits are kept when Sunset loses focus; once kept, nothing is left to keep`() async throws {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "pw-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let passwords = try await unlocked(folder, time)
        var card = try passwords.add(from: .card, title: "")
        card.title = "Amex"
        passwords.noteEdit(card)
        #expect(!passwords.pending.isEmpty)
        passwords.keepPending()
        #expect(passwords.pending.isEmpty && passwords.entries.map(\.title) == ["Amex"])
    }
}
