import Foundation
import Testing

@testable import SunsetCredentials

/// Bitwarden's JSON export, plain (roadmap 0095 E): its four kinds of item, each become the vault's own entry of that kind; folders,
/// favourites, notes, custom fields and every address kept; what is in the trash, or encrypted, or not an export, said and not guessed at.
/// The shape is from Bitwarden's documented export as remembered, not from a file checked.
@Suite("Importing Bitwarden's JSON")
struct BitwardenImportTests {
    static let export = """
        {
          "encrypted": false,
          "folders": [{"id": "f1", "name": "Work"}, {"id": "f2", "name": "Family"}],
          "items": [
            {"id": "1", "organizationId": null, "folderId": "f1", "type": 1, "reprompt": 0, "name": "Mail",
             "notes": "hello\\nworld", "favorite": true,
             "fields": [{"name": "PIN", "value": "1234", "type": 1}, {"name": "Region", "value": "EU", "type": 0},
                        {"name": "Primary", "value": "true", "type": 2}],
             "login": {"uris": [{"match": null, "uri": "https://mail.example.com/in"}, {"match": null, "uri": "mail.example.net"}],
                       "username": "ada", "password": "pw1",
                       "totp": "otpauth://totp/Mail:ada?secret=JBSWY3DPEHPK3PXP&issuer=Mail"},
             "collectionIds": null, "revisionDate": "2024-01-01T00:00:00.000Z", "creationDate": "2023-01-01T00:00:00.000Z",
             "deletedDate": null},
            {"id": "2", "folderId": null, "type": 2, "name": "Plan", "notes": "the plan", "favorite": false,
             "secureNote": {"type": 0}, "deletedDate": null},
            {"id": "3", "folderId": "f2", "type": 3, "name": "Amex", "notes": null, "favorite": false,
             "card": {"cardholderName": "Ada L", "brand": "Amex", "number": "378282246310005", "expMonth": "4",
                      "expYear": "2030", "code": "1234"}, "deletedDate": null},
            {"id": "4", "folderId": null, "type": 4, "name": "Me", "notes": null, "favorite": false,
             "identity": {"title": "Ms", "firstName": "Ada", "middleName": "A", "lastName": "Lovelace", "address1": "1 Road",
                          "address2": "Flat 2", "address3": null, "city": "London", "state": "England", "postalCode": "N1 9GU",
                          "country": "GB", "company": "Engines", "email": "ada@example.com", "phone": "+44 20 7946 0000",
                          "ssn": "123-45-6789", "username": "ada", "passportNumber": null, "licenseNumber": null},
             "deletedDate": null},
            {"id": "5", "folderId": null, "type": 1, "name": "Old", "notes": null, "favorite": false,
             "login": {"uris": [], "username": "o", "password": "p", "totp": null}, "deletedDate": "2024-02-02T00:00:00.000Z"},
            {"id": "6", "folderId": null, "type": 9, "name": "Future", "notes": null, "favorite": false, "deletedDate": null}
          ]
        }
        """

    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    private func value(_ entry: VaultEntry, _ name: String) -> String? {
        entry.field(named: name)?.value
    }

    @Test
    func `a login: its fields, folder, favourite, notes, first address, other addresses, custom fields, one-time code`()
        throws
    {
        let imported = try LoginImport.readBitwarden(Self.export, site: site)
        #expect(imported.source == .bitwarden)
        let mail = try #require(imported.entries.first { $0.title == "Mail" })
        #expect(mail.template == EntryTemplate.login.id)
        #expect(value(mail, "Username") == "ada" && value(mail, "Password") == "pw1")
        #expect(value(mail, "Website") == "https://mail.example.com/in")
        #expect(
            value(mail, "Website 2") == "https://mail.example.net",
            "another address is kept, with the scheme a bare host lacks"
        )
        #expect(value(mail, "One-Time Code")?.hasPrefix("otpauth://totp/Mail:ada") == true)
        #expect(mail.folder == "Work" && mail.isFavorite && mail.note == "hello\nworld")
        #expect(
            value(mail, "PIN") == "1234" && mail.field(named: "PIN")?.kind == .concealed,
            "a hidden custom field stays hidden"
        )
        #expect(value(mail, "Region") == "EU" && mail.field(named: "Region")?.kind == .text)
        #expect(value(mail, "Primary") == "true")
    }

    @Test func `a secure note, a card, an identity: each its own kind of entry`() throws {
        let imported = try LoginImport.readBitwarden(Self.export, site: site)
        let note = try #require(imported.entries.first { $0.title == "Plan" })
        #expect(note.template == EntryTemplate.secureNote.id && note.note == "the plan")
        let card = try #require(imported.entries.first { $0.title == "Amex" })
        #expect(card.template == EntryTemplate.card.id && card.folder == "Family")
        #expect(value(card, "Cardholder") == "Ada L" && value(card, "Number") == "378282246310005")
        #expect(
            value(card, "Expiry") == "2030-04" && value(card, "Security Code") == "1234"
                && value(card, "Brand") == "Amex"
        )
        let person = try #require(imported.entries.first { $0.title == "Me" })
        #expect(person.template == EntryTemplate.identity.id)
        #expect(value(person, "First Name") == "Ada A" && value(person, "Last Name") == "Lovelace")
        #expect(value(person, "Email") == "ada@example.com" && value(person, "Phone") == "+44 20 7946 0000")
        #expect(value(person, "Street") == "1 Road\nFlat 2" && value(person, "City") == "London")
        #expect(value(person, "Postal Code") == "N1 9GU" && value(person, "Region") == "England")
        #expect(value(person, "Country") == "GB" && person.field(named: "Address") == nil)
        #expect(value(person, "SSN") == "123-45-6789" && person.field(named: "SSN")?.kind == .concealed)
        #expect(value(person, "Company") == "Engines" && value(person, "Title") == "Ms")
    }

    @Test func `the trash and kinds we do not know are left out and said, the rest imported`() throws {
        let imported = try LoginImport.readBitwarden(Self.export, site: site)
        #expect(imported.entries.map(\.title) == ["Mail", "Plan", "Amex", "Me"])
        #expect(
            imported.skipped == [
                LoginImport.Skipped(row: 5, reason: .deleted), LoginImport.Skipped(row: 6, reason: .unknownKind)
            ]
        )
        #expect(imported.report.first == "1 login, 1 secure note, 1 card, 1 identity")
    }

    @Test func `an encrypted export, a file that is not an export, a damaged one: refused, each for its own reason`() {
        #expect(throws: LoginImport.Failure.encrypted) {
            try LoginImport.readBitwarden(
                #"{"encrypted": true, "encKeyValidation_DO_NOT_EDIT": "2.x", "data": "2.y"}"#,
                site: site
            )
        }
        #expect(throws: LoginImport.Failure.notAnExport) { try LoginImport.readBitwarden("[1, 2]", site: site) }
        #expect(throws: LoginImport.Failure.notAnExport) {
            try LoginImport.readBitwarden(#"{"items": "no"}"#, site: site)
        }
        #expect(throws: LoginImport.Failure.notAnExport) { try LoginImport.readBitwarden("not json", site: site) }
        #expect(throws: LoginImport.Failure.notAnExport) { try LoginImport.readBitwarden("", site: site) }
        #expect(throws: LoginImport.Failure.notAnExport) {
            try LoginImport.readBitwarden(#"{"folders": []}"#, site: site)
        }
    }

    @Test func `an export with no items is an export with nothing in it`() throws {
        let imported = try LoginImport.readBitwarden(#"{"encrypted": false, "folders": [], "items": []}"#, site: site)
        #expect(imported.entries.isEmpty && imported.skipped.isEmpty)
    }

    @Test func `a card's expiry that cannot be read is left out and said; the card is kept`() throws {
        let file = #"""
            {"items": [{"type": 3, "name": "C", "card": {"number": "4111111111111111", "expMonth": "13", "expYear": "x"}}]}
            """#
        let imported = try LoginImport.readBitwarden(file, site: site)
        #expect(imported.entries.count == 1 && value(imported.entries[0], "Expiry")?.isEmpty != false)
        #expect(imported.warnings == [LoginImport.Warning(row: 1, reason: .unreadableExpiry)])
    }

    @Test func `a two-digit year is this century's, a month is padded`() throws {
        let file =
            #"{"items": [{"type": 3, "name": "C", "card": {"number": "4111111111111111", "expMonth": "7", "expYear": "29"}}]}"#
        #expect(value(try LoginImport.readBitwarden(file, site: site).entries[0], "Expiry") == "2029-07")
    }

    @Test func `the same file imported twice adds nothing the second time, notes and cards included`() throws {
        let first = try LoginImport.readBitwarden(Self.export, site: site).leavingOut(held: [], site: site)
        let second = try LoginImport.readBitwarden(Self.export, site: site).leavingOut(held: first.entries, site: site)
        #expect(first.entries.count == 4 && second.entries.isEmpty && second.duplicates == 4)
    }
}
