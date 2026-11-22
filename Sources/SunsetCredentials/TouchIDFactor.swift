import CryptoKit
public import Foundation
public import LocalAuthentication
package import Security
package import SunsetStorage

/// This Mac's Secure Enclave as a vault's factor: two Secure Enclave keys, P-256 and ML-KEM-1024, give a wrap key
/// (`EnclaveWrap`) only with Touch ID, and only while the fingers enrolled are those of when it was set
/// (`.biometryCurrentSet`: a finger added later does not open the vault). The key that wraps the vault's key is derived from
/// it for that vault. What is kept (`bytes`) holds no key: the keys are blobs only this Mac's Secure Enclave opens.
public struct TouchIDFactor: Equatable, Sendable {
    /// The Secure Enclave did not give the key: Touch ID refused or was cancelled, the fingers enrolled changed, or the
    /// record is not this Mac's or was changed.
    public struct Refused: Error, Equatable {}

    package var record: EnclaveWrap.Record

    /// The factor's keys: used only with Touch ID, by the fingers enrolled when it was set.
    package static let flags: SecAccessControlCreateFlags = [.privateKeyUsage, .biometryCurrentSet]

    /// A new factor for `vault`, Touch ID asked for once now through `context`, and the key it wraps the vault's key with.
    public static func make(vault: UUID, context: LAContext? = nil) throws(Refused) -> (TouchIDFactor, Data) {
        guard
            let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, flags, nil)
        else { throw Refused() }
        return try make(vault: vault, access: access)
    }

    /// A new factor whose keys are made under `access` (the tests' ask no one).
    package static func make(vault: UUID, access: SecAccessControl) throws(Refused) -> (TouchIDFactor, Data) {
        guard SecureEnclave.isAvailable, let made = try? EnclaveWrap.make(access: access) else { throw Refused() }
        let factor = TouchIDFactor(record: made.record)
        return (factor, Self.derive(made.wrapKey, vault: vault))
    }

    /// The factor as kept.
    public init(_ bytes: Data) throws(Refused) {
        guard let record = try? EnclaveWrap.Record(bytes) else { throw Refused() }
        self.record = record
    }

    package init(record: EnclaveWrap.Record) {
        self.record = record
    }

    public var bytes: Data {
        record.bytes
    }

    /// The key that wraps `vault`'s key; Touch ID is asked for through `context` (one prompt for both keys).
    public func factorKey(vault: UUID, context: LAContext? = nil) throws(Refused) -> Data {
        guard let wrap = try? EnclaveWrap.open(record, context: context) else { throw Refused() }
        return Self.derive(wrap, vault: vault)
    }

    private static func derive(_ wrap: Data, vault: UUID) -> Data {
        FactorKey.derive(wrap, kind: "touch-id", vault: vault)
    }
}
