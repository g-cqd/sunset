import Foundation
import Testing

@testable import SunsetStorage

@Suite("Sealing: what is kept is unreadable without the key, and cannot be swapped or altered")
struct SealTests {
    private let key = StorageKey(bytes: Data((0 ..< 32).map { UInt8($0) }))
    private let text = Data("# Tides\n\nThe North Sea turns twice a day.\n".utf8)

    @Test func `what is sealed opens to what it was, and holds none of it in the clear`() throws {
        let seal = Seal(key: key, purpose: .document)
        let sealed = try seal.seal(text, identity: "doc-1")
        #expect(try seal.open(sealed, identity: "doc-1") == text)
        #expect(Seal.isSealed(sealed) && !Seal.isSealed(text))
        #expect(sealed.count == text.count + Seal.overhead)
        #expect(sealed.range(of: Data("Tides".utf8)) == nil)
        #expect(try seal.seal(text, identity: "doc-1") != sealed, "a new nonce each time")
    }

    @Test func `it cannot be opened as another thing, for another purpose, or after a change`() throws {
        let seal = Seal(key: key, purpose: .document)
        let sealed = try seal.seal(text, identity: "doc-1")
        #expect(throws: SealFailure.damaged) { try seal.open(sealed, identity: "doc-2") }
        #expect(throws: SealFailure.damaged) { try Seal(key: key, purpose: .session).open(sealed, identity: "doc-1") }
        var altered = sealed
        altered[altered.count - 20] ^= 1
        #expect(throws: SealFailure.damaged) { try seal.open(altered, identity: "doc-1") }
        #expect(throws: SealFailure.damaged) { try seal.open(sealed.dropLast(3), identity: "doc-1") }
    }

    @Test func `sealed with another key is told apart from damage; plain data and later formats are named`() throws {
        let sealed = try Seal(key: key, purpose: .document).seal(text, identity: "d")
        let other = Seal(key: StorageKey(bytes: Data(repeating: 9, count: 32)), purpose: .document)
        #expect(throws: SealFailure.otherKey) { try other.open(sealed, identity: "d") }
        #expect(throws: SealFailure.notSealed) { try other.open(text, identity: "d") }
        var later = sealed
        later[4] = 99
        #expect(throws: SealFailure.unknownVersion) {
            try Seal(key: key, purpose: .document).open(later, identity: "d")
        }
    }

    @Test func `an empty thing seals and opens`() throws {
        let seal = Seal(key: key, purpose: .state)
        #expect(try seal.open(seal.seal(Data(), identity: "x"), identity: "x") == Data())
    }
}
