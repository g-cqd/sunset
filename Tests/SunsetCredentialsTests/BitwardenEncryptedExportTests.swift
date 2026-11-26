import AemiArgon2
import CommonCrypto
import CryptoKit
import Foundation
import Testing

@testable import SunsetCredentials

/// Tests Bitwarden password-protected JSON export decryption (`PBKDF2-HMAC-SHA256` & `Argon2id`, AES-256-CBC +
/// HMAC-SHA256 — roadmap 0095 E / t104).
@Suite("Bitwarden password-protected JSON export") struct BitwardenEncryptedExportTests {
    private let plain = """
        {
          "encrypted": false,
          "folders": [{"id": "f1", "name": "Work"}],
          "items": [
            {
              "type": 1,
              "name": "GitHub",
              "folderId": "f1",
              "notes": "2fa enabled",
              "favorite": true,
              "login": {
                "username": "octocat",
                "password": "super-secret-password",
                "uris": [{"uri": "https://github.com/login"}],
                "totp": "JBSWY3DPEHPK3PXP"
              }
            }
          ]
        }
        """

    private func site(_ host: String) -> String? {
        let parts = host.split(separator: ".")
        return parts.count >= 2 ? parts.suffix(2).joined(separator: ".") : host
    }

    private func seal(
        plainJSON: String,
        password: String,
        salt: String,
        kdfType: Int,
        iterations: Int,
        memoryMiB: Int = 1,
        parallelism: Int = 1
    ) throws -> String {
        let masterKey: Data
        if kdfType == 0 {
            masterKey = try #require(
                BitwardenEncryptedExport.pbkdf2SHA256(
                    password: Data(password.utf8),
                    salt: Data(salt.utf8),
                    iterations: iterations
                )
            )
        } else {
            let hashedSalt = Data(SHA256.hash(data: Data(salt.utf8)))
            let params = try Argon2.Parameters(
                variant: .id,
                memoryKiB: memoryMiB * 1024,
                passes: iterations,
                lanes: parallelism,
                tagLength: 32
            )
            masterKey = Data(
                try Argon2.hash(
                    password: Array(password.utf8),
                    salt: Array(hashedSalt),
                    parameters: params,
                    threads: parallelism
                )
            )
        }
        let encKey = BitwardenEncryptedExport.hkdfExpand32(prk: masterKey, info: Data("enc".utf8))
        let macKey = BitwardenEncryptedExport.hkdfExpand32(prk: masterKey, info: Data("mac".utf8))
        func cipherString(_ data: Data) throws -> String {
            let iv = Data((0 ..< 16).map { _ in UInt8.random(in: 0 ... 255) })
            let ct = try #require(
                BitwardenEncryptedExport.aes256CBCCrypt(
                    operation: CCOperation(kCCEncrypt),
                    key: encKey,
                    iv: iv,
                    input: data
                )
            )
            var signed = Data()
            signed.append(iv)
            signed.append(ct)
            let mac = Data(HMAC<SHA256>.authenticationCode(for: signed, using: macKey))
            return "2.\(iv.base64EncodedString())|\(ct.base64EncodedString())|\(mac.base64EncodedString())"
        }
        let validation = try cipherString(Data(UUID().uuidString.utf8))
        let dataCipher = try cipherString(Data(plainJSON.utf8))
        let extra = kdfType == 1 ? ",\"kdfMemory\":\(memoryMiB),\"kdfParallelism\":\(parallelism)" : ""
        return """
            {"encrypted":true,"passwordProtected":true,"salt":"\(salt)","kdfType":\(kdfType),"kdfIterations":\(iterations)\(extra),"encKeyValidation_DO_NOT_EDIT":"\(validation)","data":"\(dataCipher)"}
            """
    }

    @Test func `decrypts PBKDF2-HMAC-SHA256 password-protected export and refuses wrong password`() throws {
        let sealed = try seal(
            plainJSON: plain,
            password: "export-password-123",
            salt: "salt-pbkdf2-test",
            kdfType: 0,
            iterations: 2_000
        )
        #expect(LoginImport.isPasswordProtectedBitwarden(sealed))
        #expect(throws: LoginImport.Failure.encrypted) {
            try LoginImport.readFile(sealed, site: site)
        }
        #expect(throws: LoginImport.Failure.encrypted) {
            try LoginImport.readEncryptedBitwarden(sealed, password: "wrong-password", site: site)
        }

        let imported = try LoginImport.readEncryptedBitwarden(sealed, password: "export-password-123", site: site)
        #expect(imported.source == .bitwarden)
        let entry = try #require(imported.entries.first)
        #expect(entry.title == "GitHub")
        #expect(entry.folder == "Work")
        #expect(entry.isFavorite)
        #expect(entry.field(named: "Username")?.value == "octocat")
        #expect(entry.field(named: "Password")?.value == "super-secret-password")
    }

    @Test func `decrypts Argon2id password-protected export and rejects tampered MAC`() throws {
        let sealed = try seal(
            plainJSON: plain,
            password: "argon2-export-password",
            salt: "salt-argon2-test",
            kdfType: 1,
            iterations: 1,
            memoryMiB: 1,
            parallelism: 1
        )
        let imported = try LoginImport.readEncryptedBitwarden(sealed, password: "argon2-export-password", site: site)
        #expect(imported.entries.count == 1)
        #expect(imported.entries[0].field(named: "Username")?.value == "octocat")

        let tampered = sealed.replacing("==", with: "AA")
        if tampered != sealed {
            #expect(throws: LoginImport.Failure.self) {
                try LoginImport.readEncryptedBitwarden(tampered, password: "argon2-export-password", site: site)
            }
        }
    }
}
