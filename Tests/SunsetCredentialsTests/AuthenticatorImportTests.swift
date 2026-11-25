import Foundation
import Testing

@testable import SunsetCredentials

/// Authenticator JSON imports (roadmap 0093 C / t102): Aegis, 2FAS, and andOTP plain JSON exports, encrypted export
/// rejection, auto-sniffing via `LoginImport.readFile`, and HOTP counter advancement (`OneTimeCodeField.advancingCounterURI`).
@Suite("Authenticator JSON imports & HOTP counter")
struct AuthenticatorImportTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    @Test func `imports Aegis plain JSON with TOTP, HOTP, and Steam, and rejects encrypted Aegis`() throws {
        let aegis = #"""
            {
              "version": 1,
              "header": { "slots": null, "params": null },
              "db": {
                "version": 2,
                "entries": [
                  {
                    "type": "totp",
                    "name": "alice@example.com",
                    "issuer": "GitHub",
                    "note": "work account",
                    "favorite": true,
                    "groups": ["Dev"],
                    "info": { "secret": "JBSWY3DPEHPK3PXP", "algo": "SHA1", "digits": 6, "period": 30 }
                  },
                  {
                    "type": "hotp",
                    "name": "ops",
                    "issuer": "CorpVPN",
                    "info": { "secret": "JBSWY3DPEHPK3PXP", "algo": "SHA256", "digits": 8, "counter": 7 }
                  },
                  {
                    "type": "steam",
                    "name": "player1",
                    "issuer": "Steam",
                    "info": { "secret": "JBSWY3DPEHPK3PXP", "algo": "SHA1", "digits": 5, "period": 30 }
                  },
                  {
                    "type": "totp",
                    "name": "bad",
                    "issuer": "Broken",
                    "info": { "secret": "!!!NOT-BASE32!!!", "algo": "SHA1", "digits": 6, "period": 30 }
                  }
                ]
              }
            }
            """#

        let imported = try LoginImport.readFile(aegis, site: site)
        #expect(imported.source == .aegis)
        #expect(imported.sourceName == "Aegis Authenticator")
        #expect(imported.entries.count == 3)
        #expect(imported.warnings.count == 1)
        #expect(imported.warnings[0].reason == .unreadableCode)

        #expect(imported.entries[0].title == "GitHub")
        #expect(imported.entries[0].isFavorite)
        #expect(imported.entries[0].tags == ["Dev"])
        let hotpRaw = try #require(imported.entries[1].field(named: "One-Time Code")?.value)
        let hotpField = try #require(OneTimeCodeField(hotpRaw))
        #expect(hotpField.link.kind == .hotp && hotpField.link.counter == 7 && hotpField.link.digits == 8)

        let steamRaw = try #require(imported.entries[2].field(named: "One-Time Code")?.value)
        let steamField = try #require(OneTimeCodeField(steamRaw))
        #expect(steamField.link.kind == .steam)

        // Encrypted Aegis has `"db"` as a base64 string.
        let encrypted = #"{"version": 1, "db": "encryptedBase64Payload=="}"#
        #expect(throws: LoginImport.Failure.encrypted) {
            _ = try LoginImport.readFile(encrypted, site: site)
        }
    }

    @Test func `imports 2FAS plain JSON with groups and rejects encrypted 2FAS`() throws {
        let twoFAS = #"""
            {
              "schemaVersion": 4,
              "groups": [{ "id": "g1", "name": "Cloud" }],
              "services": [
                {
                  "name": "AWS",
                  "secret": "JBSWY3DPEHPK3PXP",
                  "groupId": "g1",
                  "otp": { "label": "root", "account": "root@aws", "issuer": "AWS", "digits": 6, "period": 30, "algorithm": "SHA1", "tokenType": "TOTP" }
                }
              ]
            }
            """#

        let imported = try LoginImport.readFile(twoFAS, site: site)
        #expect(imported.source == .twoFAS)
        #expect(imported.entries.count == 1)
        #expect(imported.entries[0].title == "AWS")
        #expect(imported.entries[0].folder == "Cloud")
        #expect(imported.entries[0].field(named: "Username")?.value == "root@aws")

        let encrypted = #"{"schemaVersion": 4, "services": [], "servicesEncrypted": "ciphertext"}"#
        #expect(throws: LoginImport.Failure.encrypted) {
            _ = try LoginImport.readFile(encrypted, site: site)
        }
    }

    @Test func `imports andOTP JSON array and advances HOTP counters`() throws {
        let andOTP = #"""
            [
              {
                "secret": "JBSWY3DPEHPK3PXP",
                "issuer": "GitLab",
                "label": "dev@gitlab",
                "digits": 6,
                "type": "TOTP",
                "algorithm": "SHA1",
                "period": 30,
                "tags": ["Work"]
              },
              {
                "secret": "JBSWY3DPEHPK3PXP",
                "issuer": "HardwareKey",
                "label": "slot1",
                "digits": 6,
                "type": "HOTP",
                "algorithm": "SHA1",
                "counter": 41
              }
            ]
            """#

        let imported = try LoginImport.readFile(andOTP, site: site)
        #expect(imported.source == .andOTP)
        #expect(imported.entries.count == 2)
        #expect(imported.entries[0].tags == ["Work"])

        let hotpValue = try #require(imported.entries[1].field(named: "One-Time Code")?.value)
        let field = try #require(OneTimeCodeField(hotpValue))
        #expect(field.link.counter == 41)
        let nextURI = try #require(field.advancingCounterURI)
        let advanced = try #require(OneTimeCodeField(nextURI))
        #expect(advanced.link.counter == 42)
        #expect(advanced.code(at: Date(timeIntervalSince1970: 0)) == field.next(at: Date(timeIntervalSince1970: 0)))

        // TOTP does not advance a counter.
        let totpValue = try #require(imported.entries[0].field(named: "One-Time Code")?.value)
        #expect(try #require(OneTimeCodeField(totpValue)).advancingCounterURI == nil)
    }
}
