import CryptoKit
import Foundation
import Security
import SunsetRuntime
import SunsetTestSupport
import Testing

@testable import SunsetCredentials
@testable import SunsetStorage

/// A vault made with Touch ID first (the owner's choice, 2026-11-22), its master password as the fallback and the
/// recovery code shown once. Here the Secure Enclave's keys are made under an access that asks no one; the app's ask for
/// Touch ID, by the fingers enrolled.
@MainActor
@Suite("A vault with Touch ID first", .enabled(if: SecureEnclave.isAvailable))
struct VaultTouchIDTests {
    private let cheap = MasterPassword.Cost(memoryKiB: 64, passes: 1, lanes: 1)

    private func noPrompt(_ vault: UUID) throws(TouchIDFactor.Refused) -> (TouchIDFactor, Data) {
        guard
            let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .privateKeyUsage,
                nil
            )
        else { throw TouchIDFactor.Refused() }
        return try TouchIDFactor.make(vault: vault, access: access)
    }

    @Test func `Touch ID, the password and the code each unlock it, Touch ID first`() throws {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "vault-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let place = folder.appending(path: "personal.vault").path
        let (made, code) = try Vault.create(
            at: place,
            password: "pw",
            touchID: noPrompt,
            cost: cheap,
            runtime: time.runtime,
            locks: VaultLocks()
        )
        let entry = UUID()
        try made.put(Data("secret".utf8), as: entry)
        let vault = try Vault.open(at: place, runtime: time.runtime, locks: VaultLocks())
        #expect(vault.factors == [.touchID, .password, .recoveryCode])
        try vault.unlock(touchID: nil)
        #expect(try vault.record(entry) == Data("secret".utf8))
        vault.lock.lock(.byHand)
        try vault.unlock(password: "pw")
        vault.lock.lock(.byHand)
        try vault.unlock(recoveryCode: code)
        #expect(!vault.lock.isLocked)
    }

    @Test func `a vault made without Touch ID refuses it`() throws {
        let time = TestTime()
        let folder = FileManager.default.temporaryDirectory.appending(path: "vault-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let (vault, _) = try Vault.create(
            at: folder.appending(path: "v.vault").path,
            password: "pw",
            cost: cheap,
            runtime: time.runtime,
            locks: VaultLocks()
        )
        vault.lock.lock(.byHand)
        #expect(throws: Vault.Refused.self) { try vault.unlock(touchID: nil) }
    }
}
