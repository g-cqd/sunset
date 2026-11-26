internal import AemiArgon2
internal import AemiJSONCore
import CommonCrypto
import CryptoKit
import Foundation
internal import OrderedCollections

/// Decrypts Bitwarden password-protected JSON exports (`encrypted: true`, `passwordProtected: true`,
/// `encKeyValidation_DO_NOT_EDIT`, `data` — roadmap 0095 E / t104) without leaving any plaintext on disk.
///
/// Format (Bitwarden standard):
/// - `kdfType == 0`: PBKDF2-HMAC-SHA256 (`kdfIterations`, capped `[1, 2_000_000]`) -> 32-byte key
/// - `kdfType == 1`: Argon2id (`kdfIterations`, `kdfMemory` in MiB, `kdfParallelism`, bounded) -> 32-byte key
/// - HKDF-Expand (RFC 5869, `SHA256`, PRK = 32-byte KDF key): `enc` -> 32-byte AES-256-CBC key, `mac` -> 32-byte HMAC-SHA256 key
/// - CipherString `"2.<base64(iv)>|<base64(ct)>|<base64(mac)>"`: verified with constant-time HMAC-SHA256 over `iv || ct`,
///   then AES-256-CBC decrypted with PKCS#7 padding removal.
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
            kdfType: Int(clamping: kdfType),
            iterations: Int(clamping: iterations),
            top: top
        )
        let encKey = hkdfExpand32(prk: masterKey, info: Data("enc".utf8))
        let macKey = hkdfExpand32(prk: masterKey, info: Data("mac".utf8))

        if let validation = LoginImport.jsonText(top["encKeyValidation_DO_NOT_EDIT"]), !validation.isEmpty {
            _ = try openCipherString(validation, encKey: encKey, macKey: macKey)
        }
        let plainData = try openCipherString(payload, encKey: encKey, macKey: macKey)
        guard let decoded = String(data: plainData, encoding: .utf8) else { throw .encrypted }
        return decoded
    }

    private static func deriveMasterKey(
        password: String,
        salt: Data,
        kdfType: Int,
        iterations: Int,
        top: Object
    ) throws(LoginImport.Failure) -> Data {
        switch kdfType {
            case 0:
                guard (1 ... 2_000_000).contains(iterations) else { throw .notAnExport }
                guard let key = pbkdf2SHA256(password: Data(password.utf8), salt: salt, iterations: iterations) else {
                    throw .encrypted
                }
                return key
            case 1:
                guard case .int(let memMiB)? = top["kdfMemory"],
                    case .int(let lanes)? = top["kdfParallelism"],
                    (1 ... 16).contains(iterations),
                    (1 ... 512).contains(memMiB),
                    (1 ... 16).contains(lanes)
                else { throw .notAnExport }
                let hashedSalt = Data(SHA256.hash(data: salt))
                guard
                    let params = try? Argon2.Parameters(
                        variant: .id,
                        memoryKiB: Int(memMiB) * 1024,
                        passes: iterations,
                        lanes: Int(lanes),
                        tagLength: 32
                    ),
                    let tag = try? Argon2.hash(
                        password: Array(password.utf8),
                        salt: Array(hashedSalt),
                        parameters: params,
                        threads: Int(lanes)
                    )
                else { throw .encrypted }
                return Data(tag)
            default:
                throw .notAnExport
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

    private static func openCipherString(
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
