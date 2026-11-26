import CommonCrypto
import CryptoKit
import Foundation
import Testing

@testable import SunsetCredentials

/// Bitwarden password-protected JSON exports (roadmap 0095 E / t104), checked against Bitwarden's own published test
/// vectors (sdk-internal `bitwarden-crypto`, read 2026-11-26) and an AES/HMAC vector computed by OpenSSL, not only
/// against files this code made itself.
@Suite("Bitwarden password-protected JSON export") struct BitwardenEncryptedExportTests {
    private static let katPassword = "67t9b5g67$%Dh89n"
    private static let katSalt = Data("test_key".utf8)
    /// sdk-internal `kdf.rs` `test_master_key_derive_pbkdf2`.
    private static let pbkdf2Key: [UInt8] = [
        31, 79, 104, 226, 150, 71, 177, 90, 194, 80, 172, 209, 17, 129, 132, 81, 138, 167, 69, 167, 254, 149, 2, 27, 39,
        197, 64, 42, 22, 195, 86, 75
    ]

    @Test func `PBKDF2 and Argon2id derive the keys Bitwarden's own test vectors give`() throws {
        let pbkdf2 = try BitwardenEncryptedExport.deriveMasterKey(
            password: Self.katPassword,
            salt: Self.katSalt,
            kdf: .pbkdf2(iterations: 10_000)
        )
        #expect(Array(pbkdf2) == Self.pbkdf2Key)
        // sdk-internal `kdf.rs` `test_master_key_derive_argon2`: 4 iterations, 32 MiB, 2 lanes, salt hashed first.
        let argon = try BitwardenEncryptedExport.deriveMasterKey(
            password: Self.katPassword,
            salt: Self.katSalt,
            kdf: .argon2id(iterations: 4, memoryMiB: 32, parallelism: 2)
        )
        #expect(
            Array(argon) == [
                207, 240, 225, 177, 162, 19, 163, 76, 98, 106, 179, 175, 224, 9, 17, 240, 20, 147, 237, 47, 246, 150,
                141, 184, 62, 225, 131, 242, 51, 53, 225, 242
            ]
        )
    }

    @Test func `the key is stretched into the enc and mac keys Bitwarden's test vector gives`() {
        // sdk-internal `utils.rs` `test_stretch_kdf_key`.
        let enc = BitwardenEncryptedExport.hkdfExpand32(prk: Data(Self.pbkdf2Key), info: Data("enc".utf8))
        let mac = BitwardenEncryptedExport.hkdfExpand32(prk: Data(Self.pbkdf2Key), info: Data("mac".utf8))
        #expect(
            enc.withUnsafeBytes { Array($0) } == [
                111, 31, 178, 45, 238, 152, 37, 114, 143, 215, 124, 83, 135, 173, 195, 23, 142, 134, 120, 249, 61, 132,
                163, 182, 113, 197, 189, 204, 188, 21, 237, 96
            ]
        )
        #expect(
            mac.withUnsafeBytes { Array($0) } == [
                221, 127, 206, 234, 101, 27, 202, 38, 86, 52, 34, 28, 78, 28, 185, 16, 48, 61, 127, 166, 209, 247, 194,
                87, 232, 26, 48, 85, 193, 249, 179, 155
            ]
        )
    }

    /// Made by OpenSSL 4.1.0 (`openssl enc -aes-256-cbc`, `openssl dgst -sha256 -mac HMAC` over iv then ciphertext)
    /// with the enc key 0...31, the mac key 32...63 and the iv 0xA0...0xAF.
    private static let opensslVector =
        "2.oKGio6SlpqeoqaqrrK2urw==|63JKd7y7tgbqfH2oXNoiEz+MLO2g8MawdUjoCVNh71s=|qcD5vEHL2SaTD8tC0blsFUSlf/rWKODiBImWhU5wEr0="
    private static let encKey = SymmetricKey(data: Data((0 ..< 32).map { UInt8($0) }))
    private static let macKey = SymmetricKey(data: Data((32 ..< 64).map { UInt8($0) }))

    @Test func `a type-2 string made by OpenSSL opens; a changed byte or a cut MAC does not`() throws {
        let plain = try BitwardenEncryptedExport.openCipherString(
            Self.opensslVector,
            encKey: Self.encKey,
            macKey: Self.macKey
        )
        #expect(String(decoding: plain, as: UTF8.self) == "Sunset vault export test vector")

        let parts = Self.opensslVector.dropFirst(2).split(separator: "|").map(String.init)
        var ciphertext = try #require(Data(base64Encoded: parts[1]))
        ciphertext[3] ^= 0x01
        let flipped = "2.\(parts[0])|\(ciphertext.base64EncodedString())|\(parts[2])"
        #expect(throws: LoginImport.Failure.encrypted) {
            try BitwardenEncryptedExport.openCipherString(flipped, encKey: Self.encKey, macKey: Self.macKey)
        }
        let cut =
            "2.\(parts[0])|\(parts[1])|\(Data(try #require(Data(base64Encoded: parts[2])).prefix(16)).base64EncodedString())"
        #expect(throws: LoginImport.Failure.notAnExport) {
            try BitwardenEncryptedExport.openCipherString(cut, encKey: Self.encKey, macKey: Self.macKey)
        }
        #expect(throws: LoginImport.Failure.encrypted) {
            try BitwardenEncryptedExport.openCipherString(Self.opensslVector, encKey: Self.macKey, macKey: Self.encKey)
        }
    }

    @Test func `KDF parameters are Bitwarden's import ranges, refused outside them before any work`() throws {
        #expect(
            try BitwardenEncryptedExport.kdf(type: 0, iterations: 5_000, memoryMiB: 0, parallelism: 0)
                == .pbkdf2(iterations: 5_000)
        )
        #expect(
            try BitwardenEncryptedExport.kdf(type: 1, iterations: 10, memoryMiB: 1_024, parallelism: 16)
                == .argon2id(iterations: 10, memoryMiB: 1_024, parallelism: 16)
        )
        // Type, iterations, memory (MiB), parallelism: each one step outside a range, or an unknown type.
        let refused: [[Int64]] = [
            [0, 4_999, 0, 0], [0, 2_000_001, 0, 0], [1, 1, 16, 1], [1, 11, 16, 1], [1, 2, 15, 1], [1, 2, 1_025, 1],
            [1, 2, 16, 0], [1, 2, 16, 17], [2, 600_000, 0, 0]
        ]
        for row in refused {
            #expect(throws: LoginImport.Failure.notAnExport, "\(row)") {
                try BitwardenEncryptedExport.kdf(
                    type: row[0],
                    iterations: row[1],
                    memoryMiB: row[2],
                    parallelism: row[3]
                )
            }
        }
    }

    // MARK: - Whole files

    private let plain = """
        {"encrypted": false, "folders": [{"id": "f1", "name": "Work"}], "items": [{"type": 1, "name": "GitHub",
        "folderId": "f1", "favorite": true, "login": {"username": "octocat", "password": "super-secret-password",
        "uris": [{"uri": "https://github.com/login"}]}}]}
        """

    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    /// A file sealed as Bitwarden seals one, with `kdf` (its key derivation is the code under test, checked above
    /// against Bitwarden's vectors; the AES and HMAC here are CommonCrypto's and CryptoKit's).
    private func seal(_ json: String, password: String, kdf: BitwardenEncryptedExport.KDF, validation: Bool = true)
        throws -> String
    {
        let salt = "c2FsdC1mb3ItdGVzdA=="
        let key = try BitwardenEncryptedExport.deriveMasterKey(password: password, salt: Data(salt.utf8), kdf: kdf)
        let enc = BitwardenEncryptedExport.hkdfExpand32(prk: key, info: Data("enc".utf8))
        let mac = BitwardenEncryptedExport.hkdfExpand32(prk: key, info: Data("mac".utf8))
        func cipherString(_ text: String) throws -> String {
            let iv = Data((0 ..< 16).map { _ in UInt8.random(in: 0 ... 255) })
            let ciphertext = try #require(
                BitwardenEncryptedExport.aes256CBCCrypt(
                    operation: CCOperation(kCCEncrypt),
                    key: enc,
                    iv: iv,
                    input: Data(text.utf8)
                )
            )
            let tag = Data(HMAC<SHA256>.authenticationCode(for: iv + ciphertext, using: mac))
            return "2.\(iv.base64EncodedString())|\(ciphertext.base64EncodedString())|\(tag.base64EncodedString())"
        }
        let kdfFields =
            switch kdf {
                case .pbkdf2(let iterations): "\"kdfType\":0,\"kdfIterations\":\(iterations)"
                case .argon2id(let iterations, let memory, let lanes):
                    "\"kdfType\":1,\"kdfIterations\":\(iterations),\"kdfMemory\":\(memory),\"kdfParallelism\":\(lanes)"
            }
        let check = validation ? ",\"encKeyValidation_DO_NOT_EDIT\":\"\(try cipherString(UUID().uuidString))\"" : ""
        return "{\"encrypted\":true,\"passwordProtected\":true,\"salt\":\"\(salt)\",\(kdfFields)\(check),"
            + "\"data\":\"\(try cipherString(json))\"}"
    }

    @Test(arguments: [
        BitwardenEncryptedExport.KDF.pbkdf2(iterations: 5_000),
        .argon2id(iterations: 2, memoryMiB: 16, parallelism: 1)
    ])
    func `a sealed file opens with its password only`(kdf: BitwardenEncryptedExport.KDF) throws {
        let sealed = try seal(plain, password: "export-password-123", kdf: kdf)
        #expect(LoginImport.isPasswordProtectedBitwarden(sealed))
        #expect(throws: LoginImport.Failure.encrypted) { try LoginImport.readFile(sealed, site: site) }
        #expect(throws: LoginImport.Failure.encrypted) {
            try LoginImport.readEncryptedBitwarden(sealed, password: "wrong-password", site: site)
        }
        let imported = try LoginImport.readEncryptedBitwarden(sealed, password: "export-password-123", site: site)
        let entry = try #require(imported.entries.first)
        #expect(imported.source == .bitwarden && imported.entries.count == 1)
        #expect(entry.title == "GitHub" && entry.folder == "Work" && entry.isFavorite)
        #expect(entry.field(named: "Username")?.value == "octocat")
        #expect(entry.field(named: "Password")?.value == "super-secret-password")
    }

    @Test func `a file without its key check is not an export, as Bitwarden's importer has it`() throws {
        let sealed = try seal(plain, password: "pw-pw-pw", kdf: .pbkdf2(iterations: 5_000), validation: false)
        #expect(throws: LoginImport.Failure.notAnExport) {
            try LoginImport.readEncryptedBitwarden(sealed, password: "pw-pw-pw", site: site)
        }
    }
}
