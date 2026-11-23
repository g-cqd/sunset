import CryptoKit
import Foundation
import Security

/// Chrome extension packages (CRX3) for tests, signed as Chrome's are: RSA or ECDSA P-256 proofs of the archive and the
/// signed header data, the id made from one of the keys.
enum SignedCRX {
    struct Missing: Error {}

    private static func require<T>(_ value: T?) throws -> T {
        guard let value else { throw Missing() }
        return value
    }

    static let zip = Data([0x50, 0x4B, 0x03, 0x04]) + Data("an archive's bytes".utf8)

    private static func varint(_ value: Int) -> Data {
        var value = UInt64(value)
        var out = Data()
        repeat {
            let byte = UInt8(value & 0x7F)
            value >>= 7
            out.append(value == 0 ? byte : byte | 0x80)
        } while value != 0
        return out
    }

    private static func field(_ number: Int, _ bytes: Data) -> Data {
        varint(number << 3 | 2) + varint(bytes.count) + bytes
    }

    /// A key the test signs with: its SubjectPublicKeyInfo, and a signer.
    struct Signer {
        let spki: Data
        let field: Int
        let sign: (Data) throws -> Data
    }

    static func ecdsa() -> Signer {
        let key = P256.Signing.PrivateKey()
        return Signer(spki: key.publicKey.derRepresentation, field: 3) { try key.signature(for: $0).derRepresentation }
    }

    static func rsa() throws -> Signer {
        let attributes: [CFString: Any] = [kSecAttrKeyType: kSecAttrKeyTypeRSA, kSecAttrKeySizeInBits: 2048]
        let made = SecKeyCreateRandomKey(attributes as CFDictionary, nil)
        let key = try require(made)
        let publicKey = try require(SecKeyCopyPublicKey(key))
        let exported = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
        let pkcs1 = try require(exported)
        // SubjectPublicKeyInfo: rsaEncryption's algorithm identifier, then the PKCS#1 key in a bit string.
        let algorithm = Data([0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01, 0x05, 0x00])
        func der(_ tag: UInt8, _ body: Data) -> Data {
            let count = body.count
            let length = count < 128 ? Data([UInt8(count)]) : Data([0x82, UInt8(count >> 8), UInt8(count & 0xFF)])
            return Data([tag]) + length + body
        }
        let spki = der(0x30, algorithm + der(0x03, Data([0]) + pkcs1))
        return Signer(spki: spki, field: 2) { message in
            let signature =
                SecKeyCreateSignature(key, .rsaSignatureMessagePKCS1v15SHA256, message as CFData, nil) as Data?
            return try require(signature)
        }
    }

    /// A CRX3 package: the id from `idKey`, signed by `signers`, around `archive` (altered after signing when `tamper`).
    static func package(_ signers: [Signer], idKey: Data, archive: Data = zip, tamper: Bool = false) throws -> Data {
        let crxID = Data(SHA256.hash(data: idKey).prefix(16))
        let signedHeader = field(1, crxID)
        var message = Data("CRX3 SignedData\u{0}".utf8)
        withUnsafeBytes(of: UInt32(signedHeader.count).littleEndian) { message.append(contentsOf: $0) }
        message += signedHeader + archive
        var header = Data()
        for signer in signers {
            header += field(signer.field, field(1, signer.spki) + field(2, try signer.sign(message)))
        }
        header += field(10_000, signedHeader)
        var out = Data("Cr24".utf8)
        withUnsafeBytes(of: UInt32(3).littleEndian) { out.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt32(header.count).littleEndian) { out.append(contentsOf: $0) }
        var body = archive
        if tamper { body[body.count - 1] ^= 1 }
        return out + header + body
    }

    /// A package of `zip`, signed by a new ECDSA key, its id that key's.
    static func signed(_ zip: Data) throws -> Data {
        let signer = ecdsa()
        return try package([signer], idKey: signer.spki, archive: zip)
    }
}
