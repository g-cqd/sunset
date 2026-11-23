import Foundation
import SunsetCredentials
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetAppCore

/// The master password's rules (ADR-0119, the owner's choice on the outside audit's HIGH-02): at least 12 characters when
/// the vault is made; after three wrong passwords, the next try waits 1 s, then 2, 4 … up to 30 s; a right one clears it.
@MainActor
@Suite("The master password's rules")
struct PasswordsRulesTests {
    private func made(_ time: TestTime, _ folder: URL) throws -> PasswordsModel {
        let model = PasswordsModel(
            path: folder.appending(path: "Vaults/personal.vault").path,
            cost: MasterPassword.Cost(memoryKiB: 64, passes: 1, lanes: 1),
            runtime: time.runtime,
            locks: VaultLocks()
        )
        _ = try model.create(password: "correct horse battery", again: "correct horse battery")
        model.lock()
        return model
    }

    @Test func `fewer than 12 characters do not make a vault`() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "pw-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let model = PasswordsModel(
            path: folder.appending(path: "Vaults/personal.vault").path,
            runtime: TestTime().runtime,
            locks: VaultLocks()
        )
        #expect(throws: PasswordsModel.TooShort.self) {
            try model.create(password: "elevenchars", again: "elevenchars")
        }
        #expect(model.state == .none)
        #expect(PasswordsModel.minimumLength == 12)
    }

    @Test func `after three wrong passwords each try waits longer, up to 30 s; the right one then clears it`() throws {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "pw-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let model = try made(time, folder)
        for _ in 0 ..< 2 { #expect(!model.unlock(password: "wrong") && model.retryIn == nil) }
        var waits: [Duration] = []
        for _ in 0 ..< 7 {
            #expect(!model.unlock(password: "wrong"))
            let wait = try #require(model.retryIn)
            waits.append(wait)
            // While it waits, not even the right password is tried.
            #expect(!model.unlock(password: "correct horse battery") && model.state == .locked)
            time.advance(wait)
        }
        #expect(waits == [1, 2, 4, 8, 16, 30, 30].map { Duration.seconds($0) })
        #expect(model.unlock(password: "correct horse battery") && model.state == .unlocked)
        model.lock()
        #expect(!model.unlock(password: "wrong") && model.retryIn == nil, "counted again from the start")
    }

    /// t333: the recovery code is kept by the model until the person says they kept it, whatever happens to the window
    /// that first shows it (seen closing by itself with Touch ID on, the code lost).
    @Test func `the recovery code stays until it is said kept`() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "pw-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let model = PasswordsModel(
            path: folder.appending(path: "Vaults/personal.vault").path,
            cost: MasterPassword.Cost(memoryKiB: 64, passes: 1, lanes: 1),
            runtime: TestTime().runtime,
            locks: VaultLocks()
        )
        let code = try model.create(password: "correct horse battery", again: "correct horse battery")
        #expect(model.unkeptCode == code)
        model.lock()
        #expect(model.unkeptCode == code, "not lost by locking")
        model.codeKept()
        #expect(model.unkeptCode == nil)
    }
}
