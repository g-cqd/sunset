import Foundation
import Testing

@testable import SunsetCredentials

/// Logins written as the CSV that other programs read (roadmap 0095 D, out): Apple Passwords' columns, which every importer takes; the
/// cells exactly as kept, so that a password starting with `=` is the same password in the program it goes to; only logins, the rest said.
@Suite("Exporting logins to CSV")
struct LoginExportTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    private func login(
        _ title: String,
        _ user: String,
        _ password: String,
        website: String = "https://example.com",
        note: String = ""
    )
        throws -> VaultEntry
    {
        var entry = EntryTemplate.login.makeEntry(title: title)
        for (name, value) in [("Website", website), ("Username", user), ("Password", password)] {
            entry.set(try #require(entry.field(named: name)?.id), value)
        }
        entry.note = note
        return entry
    }

    @Test func `the header is Apple Passwords', one line a login, in the order given`() throws {
        let export = LoginExport.csv(of: [try login("A", "ada", "pw1"), try login("B", "bo", "pw2")])
        let lines = export.text.split(separator: "\r\n", omittingEmptySubsequences: false)
        #expect(lines.first == "Title,URL,Username,Password,Notes,OTPAuth")
        #expect(lines.count == 4 && lines[3].isEmpty, "two lines and the line ending")
        #expect(lines[1] == "A,https://example.com,ada,pw1,,")
        #expect(export.exported == 2 && export.skipped == 0)
    }

    @Test func `cells are quoted when they hold a comma, a quote or a line break, and never otherwise changed`() throws
    {
        let entry = try login("Bank, the \"big\" one", "=ada", "+p@ss-word", note: "line one\nline two")
        let text = LoginExport.csv(of: [entry]).text
        #expect(text.contains("\"Bank, the \"\"big\"\" one\""))
        #expect(text.contains(",=ada,+p@ss-word,"), "no apostrophe in front of what starts like a formula")
        #expect(text.contains("\"line one\nline two\""))
    }

    @Test func `what is exported can be imported again, every cell the same`() throws {
        var entry = try login(
            "Mail, \"work\"",
            "ada",
            "=1+1",
            website: "https://mail.example.com/in",
            note: "a\r\nb, c"
        )
        entry.set(
            try #require(entry.field(named: "One-Time Code")?.id),
            "otpauth://totp/Mail:ada?secret=JBSWY3DPEHPK3PXP&issuer=Mail"
        )
        let back = try LoginImport.read(LoginExport.csv(of: [entry]).text, site: site)
        let again = try #require(back.entries.first)
        #expect(back.source == .applePasswords && back.entries.count == 1)
        for name in ["Website", "Username", "Password", "One-Time Code"] {
            #expect(again.field(named: name)?.value == entry.field(named: name)?.value, "\(name)")
        }
        #expect(again.title == entry.title)
        #expect(again.note == "a\r\nb, c".replacing("\r\n", with: "\n") || again.note == "a\r\nb, c")
    }

    @Test func `only logins go out; cards and notes are counted, not written`() throws {
        var card = EntryTemplate.card.makeEntry(title: "Amex")
        // A card has concealed fields too: its security code must not go out as a password.
        card.set(try #require(card.field(named: "Security Code")?.id), "123")
        let note = EntryTemplate.secureNote.makeEntry(title: "Plan")
        let export = LoginExport.csv(of: [card, try login("A", "ada", "pw1"), note])
        #expect(export.exported == 1 && export.skipped == 2)
        #expect(!export.text.contains("Amex") && !export.text.contains("Plan") && !export.text.contains("123"))
    }

    @Test func `no logins: the header alone, nothing exported`() {
        let export = LoginExport.csv(of: [])
        #expect(export.text == "Title,URL,Username,Password,Notes,OTPAuth\r\n" && export.exported == 0)
    }
}
