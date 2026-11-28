import Foundation
import Testing

@testable import SunsetCredentials

/// KeePass databases (KDBX 4) read into the vault, from files pykeepass made (`Fixtures/README.md`).
@Suite("KeePass import")
struct KeePassImportTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: nil))
        return try Data(contentsOf: url)
    }

    private static let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let site: (String) -> String? = { host in host.split(separator: ".").suffix(2).joined(separator: ".") }

    @Test(arguments: ["keepass-argon2-aes.kdbx", "keepass-aeskdf-chacha20.kdbx"])
    func `entries come with their fields, folder, tags, code, history and attachment; the recycle bin's do not`(
        file: String
    ) throws {
        let data = try fixture(file)
        #expect(LoginImport.isKeePass(data))
        let read = try LoginImport.readKeePass(data, password: "correct horse", now: Self.now, site: site)
        #expect(read.sourceName == "KeePass")
        #expect(read.entries.map(\.title).sorted() == ["Example Mail", "Just a note"])
        #expect(read.skipped.map(\.reason) == [.deleted])
        let mail = try #require(read.entries.first { $0.title == "Example Mail" })
        #expect(mail.template == EntryTemplate.login.id)
        #expect(mail.field(named: "Username")?.value == "jane@example.com")
        #expect(mail.field(named: "Password")?.value == "s3cret-newer")
        #expect(mail.field(named: "Password")?.history?.map(\.value) == ["s3cret-new"])
        #expect(mail.field(named: "Website")?.value == "https://mail.example.com")
        #expect(mail.field(named: "One-Time Code")?.value.hasPrefix("otpauth://totp/") == true)
        #expect(mail.field(named: "PIN")?.value == "4321" && mail.field(named: "PIN")?.kind == .concealed)
        #expect(mail.field(named: "Recovery")?.kind == .text)
        #expect(mail.folder == "Work / Team" && mail.tags == ["mail", "work"])
        #expect(mail.note == "line one\nline two")
        #expect(mail.attachments?.map(\.filename) == ["readme.txt"])
        #expect(mail.attachments?.first?.data == Data("hello attachment".utf8))
        let note = try #require(read.entries.first { $0.title == "Just a note" })
        #expect(note.template == EntryTemplate.secureNote.id && note.note == "nothing else")
    }

    @Test func `a key file is taken with the password; without it, or with another password, the key is wrong`() throws
    {
        let data = try fixture("keepass-argon2id-keyfile.kdbx")
        let key = try fixture("keepass-keyfile.hex")
        let read = try LoginImport.readKeePass(data, password: "pw", keyFile: key, now: Self.now, site: site)
        #expect(read.entries.first?.field(named: "Password")?.value == "with-key-file")
        #expect(throws: LoginImport.KeePassFailure.wrongKey) {
            try LoginImport.readKeePass(data, password: "pw", now: Self.now, site: site)
        }
        #expect(throws: LoginImport.KeePassFailure.wrongKey) {
            try LoginImport.readKeePass(
                try fixture("keepass-argon2-aes.kdbx"),
                password: "wrong",
                now: Self.now,
                site: site
            )
        }
    }

    @Test func `what is not KDBX 4, or damaged, is refused without guessing`() throws {
        var data = try fixture("keepass-argon2-aes.kdbx")
        var old = data
        old[10] = 3
        #expect(throws: LoginImport.KeePassFailure.oldVersion) {
            try LoginImport.readKeePass(old, password: "correct horse", now: Self.now, site: site)
        }
        data[data.count - 40] ^= 0xFF
        #expect(throws: LoginImport.KeePassFailure.unreadable) {
            try LoginImport.readKeePass(data, password: "correct horse", now: Self.now, site: site)
        }
        #expect(!LoginImport.isKeePass(Data("username,password\n".utf8)))
    }

    /// RFC 8439 §2.4.2's test vector: the stream cipher both KeePass streams use.
    @Test func `ChaCha20 gives RFC 8439's ciphertext`() throws {
        let key = (0 ..< 32).map(UInt8.init)
        let nonce: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0x4A, 0, 0, 0, 0]
        var cipher = try #require(ChaCha20(key: key, nonce: nonce, counter: 1))
        let plain = Array(
            "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
                .utf8
        )
        let out = cipher.apply(plain)
        #expect(
            out.prefix(16) == [
                0x6E, 0x2E, 0x35, 0x9A, 0x25, 0x68, 0xF9, 0x80, 0x41, 0xBA, 0x07, 0x28, 0xDD, 0x0D, 0x69, 0x81
            ]
        )
        #expect(out.suffix(2) == [0x87, 0x4D])
    }
}
