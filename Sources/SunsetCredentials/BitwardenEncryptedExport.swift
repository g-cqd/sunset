internal import AemiArgon2
internal import AemiJSONCore
import CommonCrypto
import CryptoKit
import Foundation
internal import OrderedCollections

/// Decrypts Bitwarden password-protected JSON exports (`encrypted: true`, `passwordProtected: true`,
/// `encKeyValidation_DO_NOT_EDIT`, `data` — roadmap 0095 E / t104) without leaving any plaintext on disk.
///
/// Format, as Bitwarden's own code has it (read 2026-11-26: clients `bitwarden-password-protected-importer.ts`,
/// `password-protected-kdf-config.ts`, `default-key-generation.service.ts`; sdk-internal `bitwarden-crypto` `kdf.rs`,
/// `utils.rs`), checked against their published test vectors in `BitwardenEncryptedExportTests`:
/// - the salt is the `salt` string's UTF-8 bytes;
/// - `kdfType == 0`: PBKDF2-HMAC-SHA256, `kdfIterations` in 5,000...2,000,000 -> 32 bytes;
/// - `kdfType == 1`: Argon2id v1.3 over SHA-256(salt), `kdfIterations` 2...10, `kdfMemory` 16...1,024 MiB,
///   `kdfParallelism` 1...16 -> 32 bytes;
/// - parameters outside those ranges are refused before any derivation (they are the file's, so an attacker's);
/// - HKDF-Expand (SHA-256) of that key with info `enc` and `mac` gives the AES-256-CBC and HMAC-SHA256 keys;
/// - `encKeyValidation_DO_NOT_EDIT` and `data` are type-2 strings `2.<iv>|<ciphertext>|<mac>` (base64): the MAC,
///   HMAC-SHA256 over iv then ciphertext, is checked in constant time before AES-256-CBC with PKCS#7 is undone.
enum BitwardenEncryptedExport {
    private typealias Object = OrderedDictionary<String, JSONValue>

    /// Returns true if `text` looks like a Bitwarden password-protected JSON export.
    static func isPasswordProtected(_ text: String) -> Bool {
        guard let root = try? LoginImport.parseStrictJSON(text),
            case .object(let top) = root,
            case .bool(true)? = top["encrypted"],
            case .bool(true)? = top["passwordProtected"]
        else { return false }
        return true
    }

    /// Decrypts a Bitwarden password-protected JSON export and returns its inner plain Bitwarden JSON string.
    static func decrypt(_ text: String, password: String) throws(LoginImport.Failure) -> String {
        guard case .object(let top) = try LoginImport.parseStrictJSON(text),
            case .bool(true)? = top["encrypted"],
            case .bool(true)? = top["passwordProtected"],
            let saltText = LoginImport.jsonText(top["salt"]), !saltText.isEmpty,
            let payload = LoginImport.jsonText(top["data"]), !payload.isEmpty,
            case .int(let kdfType)? = top["kdfType"],
            case .int(let iterations)? = top["kdfIterations"]
        else { throw .notAnExport }

        let masterKey = try deriveMasterKey(
            password: password,
            salt: Data(saltText.utf8),
            kdf: try kdf(type: kdfType, iterations: iterations, top: top)
        )
        let encKey = hkdfExpand32(prk: masterKey, info: Data("enc".utf8))
        let macKey = hkdfExpand32(prk: masterKey, info: Data("mac".utf8))

        guard let validation = LoginImport.jsonText(top["encKeyValidation_DO_NOT_EDIT"]), !validation.isEmpty else {
            throw .notAnExport
        }
        _ = try openCipherString(validation, encKey: encKey, macKey: macKey)
        let plainData = try openCipherString(payload, encKey: encKey, macKey: macKey)
        guard let decoded = String(data: plainData, encoding: .utf8) else { throw .encrypted }
        return decoded
    }

    /// A key derivation an export may name, with parameters Bitwarden produces.
    enum KDF: Equatable {
        case pbkdf2(iterations: Int)
        case argon2id(iterations: Int, memoryMiB: Int, parallelism: Int)
    }

    /// The file's KDF, refused (`notAnExport`) when its type is unknown or a parameter is out of Bitwarden's range.
    private static func kdf(type: Int64, iterations: Int64, top: Object) throws(LoginImport.Failure) -> KDF {
        var memory: Int64 = 0
        var lanes: Int64 = 0
        if case .int(let value)? = top["kdfMemory"] { memory = value }
        if case .int(let value)? = top["kdfParallelism"] { lanes = value }
        return try kdf(type: type, iterations: iterations, memoryMiB: memory, parallelism: lanes)
    }

    static func kdf(
        type: Int64,
        iterations: Int64,
        memoryMiB: Int64,
        parallelism: Int64
    ) throws(LoginImport.Failure) -> KDF {
        switch type {
            case 0 where (5_000 ... 2_000_000).contains(iterations):
                return .pbkdf2(iterations: Int(iterations))
            case 1
            where (2 ... 10).contains(iterations) && (16 ... 1_024).contains(memoryMiB)
                && (1 ... 16).contains(parallelism):
                return .argon2id(iterations: Int(iterations), memoryMiB: Int(memoryMiB), parallelism: Int(parallelism))
            default:
                throw .notAnExport
        }
    }

    /// The 32-byte key `password` and `salt` derive to by `kdf`.
    static func deriveMasterKey(password: String, salt: Data, kdf: KDF) throws(LoginImport.Failure) -> Data {
        switch kdf {
            case .pbkdf2(let iterations):
                guard let key = pbkdf2SHA256(password: Data(password.utf8), salt: salt, iterations: iterations) else {
                    throw .encrypted
                }
                return key
            case .argon2id(let iterations, let memoryMiB, let lanes):
                let hashedSalt = Data(SHA256.hash(data: salt))
                guard
                    let params = try? Argon2.Parameters(
                        variant: .id,
                        memoryKiB: memoryMiB * 1_024,
                        passes: iterations,
                        lanes: lanes,
                        tagLength: 32
                    ),
                    let tag = try? Argon2.hash(
                        password: Array(password.utf8),
                        salt: Array(hashedSalt),
                        parameters: params,
                        threads: lanes
                    )
                else { throw .encrypted }
                return Data(tag)
        }
    }

    /// RFC 5869 HKDF-Expand single 32-byte block (`HMAC-SHA256(prk, info || 0x01)`), matching Bitwarden's stretchKey.
    static func hkdfExpand32(prk: Data, info: Data) -> SymmetricKey {
        var msg = info
        msg.append(0x01)
        let digest = HMAC<SHA256>.authenticationCode(for: msg, using: SymmetricKey(data: prk))
        return SymmetricKey(data: Data(digest))
    }

    static func pbkdf2SHA256(password: Data, salt: Data, iterations: Int) -> Data? {
        var derived = [UInt8](repeating: 0, count: 32)
        let status = password.withUnsafeBytes { pw in
            salt.withUnsafeBytes { s in
                unsafe CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    pw.bindMemory(to: Int8.self).baseAddress,
                    password.count,
                    s.bindMemory(to: UInt8.self).baseAddress,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    UInt32(iterations),
                    &derived,
                    derived.count
                )
            }
        }
        return status == kCCSuccess ? Data(derived) : nil
    }

    static func openCipherString(
        _ cipher: String,
        encKey: SymmetricKey,
        macKey: SymmetricKey
    ) throws(LoginImport.Failure) -> Data {
        guard cipher.hasPrefix("2.") else { throw .notAnExport }
        let parts = cipher.dropFirst(2).split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count == 3,
            let iv = Data(base64Encoded: String(parts[0])), iv.count == 16,
            let ct = Data(base64Encoded: String(parts[1])), !ct.isEmpty, ct.count.isMultiple(of: 16),
            let mac = Data(base64Encoded: String(parts[2])), mac.count == 32
        else { throw .notAnExport }

        var signed = Data()
        signed.reserveCapacity(iv.count + ct.count)
        signed.append(iv)
        signed.append(ct)
        guard HMAC<SHA256>.isValidAuthenticationCode(mac, authenticating: signed, using: macKey) else {
            throw .encrypted
        }
        guard let plain = aes256CBCCrypt(operation: CCOperation(kCCDecrypt), key: encKey, iv: iv, input: ct) else {
            throw .encrypted
        }
        return plain
    }

    static func aes256CBCCrypt(
        operation: CCOperation,
        key: SymmetricKey,
        iv: Data,
        input: Data
    ) -> Data? {
        let keyData = key.withUnsafeBytes { Data(unsafe $0) }
        var out = [UInt8](repeating: 0, count: input.count + kCCBlockSizeAES128)
        var outLength = 0
        let status = keyData.withUnsafeBytes { k in
            iv.withUnsafeBytes { v in
                input.withUnsafeBytes { i in
                    unsafe CCCrypt(
                        operation,
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        k.baseAddress,
                        kCCKeySizeAES256,
                        v.baseAddress,
                        i.baseAddress,
                        input.count,
                        &out,
                        out.count,
                        &outLength
                    )
                }
            }
        }
        guard status == kCCSuccess else { return nil }
        return Data(out.prefix(outLength))
    }
}
