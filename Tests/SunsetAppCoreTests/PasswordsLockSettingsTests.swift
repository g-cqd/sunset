import Foundation
import SunsetCredentials
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetAppCore

/// The vault's locking settings (the owner, 2026-11-23): its idle time, and locking when its tab is left or its window is
/// no longer in front, each only when set.
@MainActor
@Suite("The vault's locking settings")
struct PasswordsLockSettingsTests {
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

    @Test func `the idle time set locks it then; zero never by itself`() async throws {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "pw-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let passwords = try await unlocked(folder, time)
        var mark = time.mark()
        passwords.lockAfter(minutes: 1)
        try await time.waited(since: mark)
        try await time.passToEnd(.seconds(60))
        #expect(passwords.state == .locked)
        passwords.lockAfter(minutes: 0)
        mark = time.mark()
        #expect(passwords.unlock(password: "correct horse battery"))
        try await time.pass(.seconds(24 * 3600))
        #expect(passwords.state == .unlocked)
    }

    @Test(arguments: [false, true])
    func `leaving its tab or its window locks it only when set`(set: Bool) async throws {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "pw-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let passwords = try await unlocked(folder, time)
        passwords.lockWhen = LockWhen(leavingTab: set, windowInactive: false)
        passwords.left(.tab)
        #expect(passwords.state == (set ? .locked : .unlocked))
        #expect(passwords.unlock(password: "correct horse battery"))
        passwords.lockWhen = LockWhen(leavingTab: false, windowInactive: set)
        passwords.left(.tab)
        #expect(passwords.state == .unlocked, "the tab is not the window")
        passwords.left(.window)
        #expect(passwords.state == (set ? .locked : .unlocked))
    }
}
