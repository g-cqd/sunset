import CryptoKit
public import Foundation

/// Seals what Sunset keeps (R12, roadmap 0030 step ST-2): ChaCha20-Poly1305 from the system's CryptoKit, with a key derived
/// from the storage key for one purpose, a new nonce each time, and the thing's identity bound in, so that one sealed thing
/// cannot stand in for another and a change to it is detected, not read.
///
/// The format: `SNSL`, a version byte, the key's four-byte identifier, the 12-byte nonce, the sealed bytes, the 16-byte tag.
public struct Seal: Sendable {
    public enum Purpose: String, Sendable {
        case document, session, state
    }

    private static let magic = Data("SNSL".utf8)
    private static let version: UInt8 = 1
    /// What a seal adds to the bytes it seals.
    public static let overhead = 4 + 1 + 4 + 12 + 16

    private let key: SymmetricKey
    private let identifier: Data
    private let purpose: Purpose

    public init(key: StorageKey, purpose: Purpose) {
        self.key = key.derived(purpose.rawValue)
        identifier = key.identifier
        self.purpose = purpose
    }

    /// The bytes start as a seal does.
    public static func isSealed(_ data: Data) -> Bool { data.prefix(magic.count) == magic }

    private func bound(_ identity: String) -> Data { Data("\(purpose.rawValue)\u{0}\(identity)".utf8) }

    /// - Complexity: O(the bytes).
    public func seal(_ plain: Data, identity: String) throws(SealFailure) -> Data {
        do {
            let box = try ChaChaPoly.seal(plain, using: key, authenticating: bound(identity))
            return Self.magic + [Self.version] + identifier + Data(box.nonce) + box.ciphertext + box.tag
        } catch {
            throw .damaged
        }
    }

    /// - Complexity: O(the bytes).
    public func open(_ sealed: Data, identity: String) throws(SealFailure) -> Data {
        let data = Data(sealed)
        guard Self.isSealed(data) else { throw .notSealed }
        guard data.count >= Self.overhead else { throw .damaged }
        guard data[4] == Self.version else { throw .unknownVersion }
        guard data[5 ..< 9] == identifier else { throw .otherKey }
        do {
            let box = try ChaChaPoly.SealedBox(
                nonce: ChaChaPoly.Nonce(data: data[9 ..< 21]),
                ciphertext: data[21 ..< (data.count - 16)],
                tag: data.suffix(16)
            )
            return try ChaChaPoly.open(box, using: key, authenticating: bound(identity))
        } catch {
            throw .damaged
        }
    }
}
