import Foundation
import Testing

@testable import SunsetCredentials

/// The vault written as a KeePass database (KDBX 4), read back as KeePass reads it.
@Suite("KeePass export")
struct KeePassExportTests {
    private static let now = Date(timeIntervalSince1970: 1_800_000_000)

    static func entries() -> [VaultEntry] {
        var login = EntryTemplate.login.makeEntry(title: "Example <Mail> & Co")
        LoginImport.put("Username", "jane@example.com", in: &login)
        LoginImport.put("Password", "s3cret & <new>", in: &login)
        LoginImport.put("Website", "https://mail.example.com", in: &login)
        LoginImport.put(
            "One-Time Code",
            "otpauth://totp/Example:jane?secret=JBSWY3DPEHPK3PXP&issuer=Example",
            in: &login
        )
        let section = login.addSection("Custom Fields")
        login.add(EntryField(name: "PIN", kind: .concealed, value: "4321"), to: section)
        login.add(EntryField(name: "Recovery", kind: .text, value: "plain"), to: section)
        login.note = "line one\nline two"
        login.folder = "Work / Team"
        login.tags = ["mail", "work"]
        login.addAttachment(VaultAttachment(filename: "readme.txt", data: Data("hello".utf8), addedAt: now))
        var note = EntryTemplate.secureNote.makeEntry(title: "A note")
        note.note = "only text"
        return [login, note]
    }

    @Test func `written, it reads back: fields, protected values, folders, tags, notes and attachments`() throws {
        let data = try KeePassWriter.write(Self.entries(), password: "pw", now: Self.now)
        #expect(LoginImport.isKeePass(data))
        let read = try LoginImport.readKeePass(data, password: "pw", now: Self.now, site: { $0 })
        let mail = try #require(read.entries.first { $0.title == "Example <Mail> & Co" })
        #expect(mail.field(named: "Username")?.value == "jane@example.com")
        #expect(mail.field(named: "Password")?.value == "s3cret & <new>")
        #expect(mail.field(named: "Website")?.value == "https://mail.example.com")
        #expect(mail.field(named: "One-Time Code")?.value.hasPrefix("otpauth://totp/") == true)
        #expect(mail.field(named: "PIN")?.value == "4321" && mail.field(named: "PIN")?.kind == .concealed)
        #expect(mail.field(named: "Recovery")?.kind == .text)
        #expect(mail.folder == "Work / Team" && mail.tags == ["mail", "work"] && mail.note == "line one\nline two")
        #expect(mail.attachments?.first?.data == Data("hello".utf8))
        let note = try #require(read.entries.first { $0.title == "A note" })
        #expect(note.template == EntryTemplate.secureNote.id && note.note == "only text")
        #expect(throws: LoginImport.KeePassFailure.wrongKey) {
            try LoginImport.readKeePass(data, password: "other", now: Self.now, site: { $0 })
        }
    }

    /// For the outside check: `SUNSET_KDBX_OUT` names a file the database is written to (a probe, never in the suite).
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SUNSET_KDBX_OUT"] != nil))
    func `written for KeePass to read`() throws {
        let path = try #require(ProcessInfo.processInfo.environment["SUNSET_KDBX_OUT"])
        try KeePassWriter.write(Self.entries(), password: "pw", now: Self.now).write(to: URL(fileURLWithPath: path))
    }
}
