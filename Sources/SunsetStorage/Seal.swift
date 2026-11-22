import CryptoKit
public import Foundation

/// Seals what Sunset keeps: ChaCha20-Poly1305 from the system's CryptoKit, with a key derived from the storage key for one
/// purpose, a new nonce each time, and the thing's identity bound in, so that one sealed thing cannot stand in for another
/// and a change to it is detected, not read.
///
/// The format: `SNSL`, a version byte, the key's four-byte identifier, the 12-byte nonce, the sealed bytes, the 16-byte tag.
public struct Seal: Sendable {
    public enum Purpose: String, Sendable {
        case document, session, state, cookies, siteData
        /// A vault's records and its index: sealed with the vault's own key, never the app's.
        case vaultRecord, vaultIndex
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
    public static func isSealed(_ data: Data) -> Bool {
        data.prefix(magic.count) == magic
    }

    /// What is bound into a seal for a thing of this identity: the purpose and the identity. Made once by whoever seals many
    /// things (`SealedTable`), and extended with what tells them apart.
    public func binding(_ identity: String) -> Data {
        Data("\(purpose.rawValue)\u{0}\(identity)".utf8)
    }

    /// - Complexity: O(the bytes).
    public func seal(_ plain: Data, identity: String) throws(SealFailure) -> Data {
        try seal(plain, binding: binding(identity))
    }

    public func seal(_ plain: Data, binding: Data) throws(SealFailure) -> Data {
        do {
            let box = try ChaChaPoly.seal(plain, using: key, authenticating: binding)
            return Self.magic + [Self.version] + identifier + box.combined
        } catch {
            throw .damaged
        }
    }

    /// - Complexity: O(the bytes).
    public func open(_ sealed: Data, identity: String) throws(SealFailure) -> Data {
        try open(sealed, binding: binding(identity))
    }

    /// Opens without copying `sealed`: read in place, whatever part of a larger buffer it is.
    public func open(_ sealed: Data, binding: Data) throws(SealFailure) -> Data {
        guard Self.isSealed(sealed) else { throw .notSealed }
        guard sealed.count >= Self.overhead else { throw .damaged }
        guard sealed[sealed.startIndex + 4] == Self.version else { throw .unknownVersion }
        guard sealed.dropFirst(5).prefix(4) == identifier else { throw .otherKey }
        do {
            // After the header the bytes are the nonce, the sealed bytes and the tag, as CryptoKit combines them.
            return try ChaChaPoly.open(
                ChaChaPoly.SealedBox(combined: sealed.dropFirst(9)),
                using: key,
                authenticating: binding
            )
        } catch {
            throw .damaged
        }
    }
}
