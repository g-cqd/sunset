import Foundation
import Testing

@testable import SunsetStorage

/// The storage key moved from the login Keychain to its new place without a launch that cannot open it. The first
/// launch copies it and checks the copy; a later one that opens the copy removes the old item; a new place that fails
/// leaves the key where it was.
@Suite("The storage key, moved")
struct MovingKeyVaultTests {
    private let key = Data(repeating: 7, count: 32)

    @Test func `first launch: copied and checked, the old kept; a later one: the old removed`() throws {
        let old = MemoryKeyVault()
        let new = MemoryKeyVault()
        try old.write(key)
        #expect(try MovingKeyVault(new: new, old: old).read() == key)
        #expect(new.stored == key && old.stored == key, "both, until a launch opens the new one")
        #expect(try MovingKeyVault(new: new, old: old).read() == key)
        #expect(new.stored == key && old.stored == nil)
        #expect(try MovingKeyVault(new: new, old: old).read() == key)
    }

    @Test func `a new place that cannot be used: the key stays where it was, and is read from there`() throws {
        let old = MemoryKeyVault()
        try old.write(key)
        let vault = MovingKeyVault(new: MemoryKeyVault(failing: true), old: old)
        #expect(try vault.read() == key)
        #expect(try vault.read() == key && old.stored == key)
    }

    @Test func `a key written (a new store, a restore) goes to the new place, the old item removed; else to the old`()
        throws
    {
        let old = MemoryKeyVault()
        try old.write(Data(repeating: 1, count: 32))
        let new = MemoryKeyVault()
        try MovingKeyVault(new: new, old: old).write(key)
        #expect(new.stored == key && old.stored == nil)
        let stuck = MemoryKeyVault()
        try MovingKeyVault(new: MemoryKeyVault(failing: true), old: stuck).write(key)
        #expect(stuck.stored == key)
    }

    @Test func `the new place and the old disagree: the new one is the key, the old is left`() throws {
        let old = MemoryKeyVault()
        let new = MemoryKeyVault()
        try old.write(Data(repeating: 1, count: 32))
        try new.write(key)
        #expect(try MovingKeyVault(new: new, old: old).read() == key)
        #expect(old.stored == Data(repeating: 1, count: 32), "never removed unless it is the same key")
    }

    @Test func `nothing anywhere: nil`() throws {
        #expect(try MovingKeyVault(new: MemoryKeyVault(), old: MemoryKeyVault()).read() == nil)
    }

    /// A new place that keeps something else than it was given (a broken write): the copy is checked, taken out, and
    /// the key stays in the old place, so the next launch moves it again instead of trusting a wrong copy.
    @Test func `a copy that does not read back is taken out, the old kept`() throws {
        let ordered = Data((0 ..< 32).map { UInt8($0) })
        let old = MemoryKeyVault()
        try old.write(ordered)
        let wrong = WrongVault()
        #expect(try MovingKeyVault(new: wrong, old: old).read() == ordered)
        #expect(wrong.inner.stored == nil && old.stored == ordered)
    }
}
