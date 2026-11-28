import Foundation
import Testing

@testable import SunsetCredentials

/// 1Password's `.1pux` export read into the vault (`Fixtures/README.md`).
@Suite("1Password import")
struct OnePasswordImportTests {
    private func fixture() throws -> Data {
        let url = try #require(Bundle.module.url(forResource: "Fixtures/onepassword.1pux", withExtension: nil))
        return try Data(contentsOf: url)
    }

    private let site: (String) -> String? = { host in host.split(separator: ".").suffix(2).joined(separator: ".") }

    @Test func `each item becomes the entry of its kind, with its fields, folder, tags, history and file`() throws {
        let data = try fixture()
        #expect(LoginImport.isOnePasswordExport(data))
        let read = try LoginImport.readOnePassword(data, site: site)
        #expect(read.sourceName == "1Password")
        #expect(read.entries.map(\.title) == ["Example Mail", "Visa", "Me", "A note", "Scan", "DB Server"])
        #expect(read.skipped.map(\.reason) == [.archived])

        let mail = read.entries[0]
        #expect(mail.template == EntryTemplate.login.id && mail.isFavorite && mail.folder == "Personal")
        #expect(mail.field(named: "Username")?.value == "jane@example.com")
        #expect(mail.field(named: "Password")?.value == "pw-current")
        #expect(mail.field(named: "Password")?.history?.map(\.value) == ["pw-older", "pw-old"])
        #expect(mail.field(named: "Website")?.value == "https://mail.example.com")
        #expect(mail.field(named: "One-Time Code")?.value.hasPrefix("otpauth://totp/") == true)
        #expect(mail.field(named: "recovery code")?.kind == .concealed)
        #expect(mail.field(named: "member since")?.value == "2020-01-01")
        #expect(mail.tags == ["mail", "work"] && mail.note == "a note")

        let card = read.entries[1]
        #expect(card.template == EntryTemplate.card.id)
        #expect(card.field(named: "Cardholder")?.value == "Jane Doe")
        #expect(card.field(named: "Number")?.value == "4111111111111111")
        #expect(card.field(named: "Security Code")?.value == "123")
        #expect(card.field(named: "Expiry")?.value == "2030-04")

        let identity = read.entries[2]
        #expect(
            identity.field(named: "First Name")?.value == "Jane"
                && identity.field(named: "Birthday")?.value == "1990-01-01"
        )
        #expect(identity.field(named: "Street")?.value.hasPrefix("1 Main St\nSpringfield") == true)

        #expect(read.entries[3].template == EntryTemplate.secureNote.id && read.entries[3].note == "just text")
        #expect(read.entries[4].attachments?.first?.filename == "scan.txt")
        #expect(read.entries[4].attachments?.first?.data == Data("scanned page\n".utf8))
        let server = read.entries[5]
        #expect(server.folder == "Work" && server.field(named: "admin password")?.kind == .concealed)
    }

    @Test func `what is not a 1Password export is refused`() throws {
        #expect(!LoginImport.isOnePasswordExport(Data("username,password\n".utf8)))
        var damaged = try fixture()
        // A byte of the zipped data changed: it inflates to another file, or none.
        damaged[damaged.count / 2] ^= 0xFF
        #expect(throws: LoginImport.Failure.notAnExport) { try LoginImport.readOnePassword(damaged, site: site) }
        #expect(ZipReader.files(Data([0x50, 0x4B, 3, 4, 0, 0])) == nil)
        #expect(CRC32.of(Array("123456789".utf8)) == 0xCBF4_3926, "the standard check value")
    }
}
