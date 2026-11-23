internal import CryptoKit
internal import Foundation
internal import Security
internal import SunsetStorage

/// A CRX3 package's signature (the outside audit's CRIT-03): its header (a protocol buffer) lists proofs, each a public key
/// and its signature of "CRX3 SignedData\0", the signed header data's length (little-endian, 32 bits), that data, and the
/// archive; the signed header data names the extension's id, the first 16 bytes of the SHA-256 of one of those keys.
/// Every proof must hold, and one must be the id's: Chrome's rule. RSA (PKCS #1 v1.5) and ECDSA P-256, both over SHA-256.
enum CRX3Signature {
    /// Throws unless `header`'s proofs sign `archive`.
    static func verify(header: Data, archive: Data) throws(ExtensionPackage.Refused) {
        var reader = ProtobufReader(Array(header))
        guard let fields = try? reader.fields() else { throw refused("a .crx whose header does not read") }
        var proofs: [(key: Data, signature: Data, rsa: Bool)] = []
        var signedHeader: Data?
        for (number, value) in fields {
            guard case .bytes(let bytes) = value else { continue }
            switch number {
                case 2, 3:
                    var inner = ProtobufReader(bytes)
                    guard let parts = try? inner.fields() else { throw refused("a .crx whose proof does not read") }
                    let key = parts.first { $0.number == 1 }.flatMap(Self.bytes)
                    let signature = parts.first { $0.number == 2 }.flatMap(Self.bytes)
                    guard let key, let signature else {
                        throw refused("a .crx with a proof missing its key or signature")
                    }
                    proofs.append((key, signature, number == 2))
                case 10_000: signedHeader = Data(bytes)
                default: continue
            }
        }
        guard let signedHeader, let crxID = Self.crxID(signedHeader) else { throw refused("a .crx without its id") }
        guard !proofs.isEmpty else { throw refused("a .crx that is not signed") }
        var message = Data("CRX3 SignedData\u{0}".utf8)
        withUnsafeBytes(of: UInt32(signedHeader.count).littleEndian) { message.append(contentsOf: $0) }
        message += signedHeader + archive
        for proof in proofs where !holds(proof, message: message) {
            throw refused("a .crx whose signature does not hold: altered, or not its signer's")
        }
        guard proofs.contains(where: { Data(SHA256.hash(data: $0.key).prefix(16)) == crxID }) else {
            throw refused("a .crx not signed by the key its id is made from")
        }
    }

    private static func refused(_ reason: String) -> ExtensionPackage.Refused {
        ExtensionPackage.Refused(reason: reason)
    }

    private static func bytes(_ field: (number: UInt64, value: ProtobufReader.Value)) -> Data? {
        if case .bytes(let bytes) = field.value { return Data(bytes) }
        return nil
    }

    /// The id in the signed header data (`SignedData.crx_id`, field 1, 16 bytes).
    private static func crxID(_ signedHeader: Data) -> Data? {
        var reader = ProtobufReader(Array(signedHeader))
        guard let id = (try? reader.fields())?.first(where: { $0.number == 1 }).flatMap(bytes), id.count == 16 else {
            return nil
        }
        return id
    }

    private static func holds(_ proof: (key: Data, signature: Data, rsa: Bool), message: Data) -> Bool {
        if !proof.rsa {
            guard let key = try? P256.Signing.PublicKey(derRepresentation: proof.key),
                let signature = try? P256.Signing.ECDSASignature(derRepresentation: proof.signature)
            else { return false }
            return key.isValidSignature(signature, for: message)
        }
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA, kSecAttrKeyClass: kSecAttrKeyClassPublic
        ]
        guard let pkcs1 = SubjectPublicKeyInfo.rsaKey(proof.key),
            let key = SecKeyCreateWithData(pkcs1 as CFData, attributes as CFDictionary, nil)
        else { return false }
        return SecKeyVerifySignature(
            key,
            .rsaSignatureMessagePKCS1v15SHA256,
            message as CFData,
            proof.signature as CFData,
            nil
        )
    }
}
