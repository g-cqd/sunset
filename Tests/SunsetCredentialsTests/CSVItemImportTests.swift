import Testing

@testable import SunsetCredentials

/// CSV rows that are notes or cards become Secure Note and Card entries (roadmap 0095 D / t104).
@Suite("CSV notes and cards import") struct CSVItemImportTests {
    private func site(_ host: String) -> String? {
        host
    }

    @Test func `note and card rows become their own entries while unknown kinds are left out`() throws {
        let csv = """
            type,name,notes,folder,favorite,login_uri,login_username,login_password,cardholder,card_number,expiry,cvv
            login,Example,,Work,1,https://example.com,alice,hunter2,,,,
            note,Wi-Fi at home,"SSID: home\nKey: secret",Home,,,,,,,,
            card,Visa,primary card,,yes,,,,Alice Doe,4111 1111 1111 1111,04/30,123
            card,Bad Expiry,,,,,,,Bob,4111111111111111,13/2030,
            identity,Me,,,,,,,,,,
            """
        let imported = try LoginImport.read(csv, site: site)
        #expect(imported.entries.count == 4)
        #expect(imported.skipped.map(\.reason) == [.notALogin])
        #expect(imported.warnings.map(\.reason) == [.unreadableExpiry])

        let note = imported.entries[1]
        #expect(note.template == EntryTemplate.secureNote.id)
        #expect(note.title == "Wi-Fi at home")
        #expect(note.note == "SSID: home\nKey: secret")
        #expect(note.folder == "Home")

        let card = imported.entries[2]
        #expect(card.template == EntryTemplate.card.id)
        #expect(card.field(named: "Cardholder")?.value == "Alice Doe")
        #expect(card.field(named: "Number")?.value == "4111111111111111")
        #expect(card.field(named: "Expiry")?.value == "2030-04")
        #expect(card.field(named: "Security Code")?.value == "123")
        #expect(card.isFavorite)
        #expect(card.note == "primary card")

        #expect(imported.entries[3].field(named: "Expiry")?.value == "")
    }

    @Test func `a notes-only export without a password column is read`() throws {
        let csv = "type,name,notes\nsecurenote,Recovery codes,abc-123\n"
        let imported = try LoginImport.read(csv, site: site)
        #expect(imported.entries.map(\.title) == ["Recovery codes"])
    }
}
