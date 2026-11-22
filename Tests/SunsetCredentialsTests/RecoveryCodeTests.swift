import Foundation
import Testing

@testable import SunsetCredentials
@testable import SunsetStorage

/// ADR-0091: a recovery code, 32 random bytes shown once, is a factor of its own. Typed back, a slip is said to be one
/// before anything is tried; the code opens only its own vault.
@Suite("A vault's recovery code")
struct RecoveryCodeTests {
    @Test func `it is 32 random bytes, shown in groups of five that read back to the same code`() throws {
        let code = RecoveryCode.generate()
        let other = RecoveryCode.generate()
        #expect(code.bytes.count == 32 && code != other)
        let groups = code.text.split(separator: "-")
        #expect(groups.count == 11 && groups.dropLast().allSatisfy { $0.count == 5 })
        #expect(try RecoveryCode(typed: code.text) == code)
    }

    @Test func `typed back as people type it: lower case, spaces, O for 0 and I or L for 1`() throws {
        let code = RecoveryCode.generate()
        let loose = code.text.lowercased().replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "0", with: "o").replacingOccurrences(of: "1", with: "l")
        #expect(try RecoveryCode(typed: "  " + loose + " ") == code)
    }

    @Test func `a slip is told as a slip: a changed character, a missing one, one that is not in the alphabet`() throws
    {
        let code = RecoveryCode.generate()
        var chars = Array(code.text)
        let index = try #require(chars.firstIndex { $0 != "-" })
        chars[index] = chars[index] == "A" ? "B" : "A"
        #expect(throws: RecoveryCode.Mistyped.self) { try RecoveryCode(typed: String(chars)) }
        #expect(throws: RecoveryCode.Mistyped.self) { try RecoveryCode(typed: String(code.text.dropLast())) }
        #expect(throws: RecoveryCode.Mistyped.self) {
            try RecoveryCode(typed: code.text.replacingOccurrences(of: "-", with: "U"))
        }
    }

    @Test func `it wraps the vault key for its vault only`() throws {
        let code = RecoveryCode.generate()
        let vault = UUID()
        let vaultKey = StorageKey.random()
        let wrapped = try WrappedKey.wrap(
            vaultKey,
            with: code.factorKey(vault: vault),
            factor: "recovery",
            vault: vault
        )
        let typed = try RecoveryCode(typed: code.text)
        #expect(try wrapped.unwrap(with: typed.factorKey(vault: vault), vault: vault).bytes == vaultKey.bytes)
        #expect(code.factorKey(vault: vault) != code.factorKey(vault: UUID()))
        #expect(throws: WrappedKey.Refused.self) {
            try wrapped.unwrap(with: RecoveryCode.generate().factorKey(vault: vault), vault: vault)
        }
    }
}
