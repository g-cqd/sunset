import Foundation
import Testing

@testable import SunsetStorage

@Suite("The key that seals what Sunset keeps")
struct StorageKeyTests {
    @Test func `the first use makes a key and keeps it; later uses read the same one`() throws {
        let vault = MemoryKeyVault()
        let first = try StorageKeyring(vault: vault).key()
        #expect(vault.stored?.count == 32)
        let second = try StorageKeyring(vault: vault).key()
        #expect(first.identifier == second.identifier)
        #expect(try StorageKeyring(vault: MemoryKeyVault()).key().identifier != first.identifier, "another key")
    }

    @Test func `a vault that cannot be used gives no key, and nothing is made`() {
        let vault = MemoryKeyVault(failing: true)
        #expect(throws: StorageKeyFailure.vault) { try StorageKeyring(vault: vault).key() }
        #expect(vault.stored == nil)
    }

    @Test func `the recovery code is the key in a form to write down, and gives the key back`() throws {
        let vault = MemoryKeyVault()
        let key = try StorageKeyring(vault: vault).key()
        let code = key.recoveryCode
        #expect(code.split(separator: "-").count == 11 && code.split(separator: "-").allSatisfy { $0.count == 5 })
        #expect(code.allSatisfy { $0 == "-" || $0.isNumber || ($0.isUppercase && !"ILOU".contains($0)) })
        let other = MemoryKeyVault()
        let restored = try StorageKeyring(vault: other).restore(code: code)
        #expect(restored.identifier == key.identifier && other.stored == vault.stored)
    }

    @Test func `a code is read as people type it; a mistyped one is refused`() throws {
        // A fixed key: whether a changed symbol passes the two check bytes is then the same at every run.
        let key = StorageKey(bytes: Data((0 ..< 32).map { UInt8($0 &* 7) }))
        let code = key.recoveryCode
        let sloppy =
            " " + code.lowercased().replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "0", with: "o")
        #expect(try StorageKey(recoveryCode: sloppy).identifier == key.identifier)
        var typo = Array(code)
        typo[3] = typo[3] == "7" ? "8" : "7"
        #expect(throws: StorageKeyFailure.badCode) { try StorageKey(recoveryCode: String(typo)) }
        #expect(throws: StorageKeyFailure.badCode) { try StorageKey(recoveryCode: "ABCDE-12345") }
        #expect(throws: StorageKeyFailure.badCode) { try StorageKey(recoveryCode: "") }
    }

    @Test func `restoring does not replace a key that is there, unless told to`() throws {
        let vault = MemoryKeyVault()
        let mine = try StorageKeyring(vault: vault).key()
        let theirs = try StorageKeyring(vault: MemoryKeyVault()).key()
        #expect(throws: StorageKeyFailure.keyExists) {
            try StorageKeyring(vault: vault).restore(code: theirs.recoveryCode)
        }
        #expect(try StorageKeyring(vault: vault).key().identifier == mine.identifier)
        let replaced = try StorageKeyring(vault: vault).restore(code: theirs.recoveryCode, replacing: true)
        #expect(replaced.identifier == theirs.identifier)
        #expect(
            try StorageKeyring(vault: vault).restore(code: theirs.recoveryCode).identifier == theirs.identifier,
            "the same key is no conflict"
        )
    }
}
