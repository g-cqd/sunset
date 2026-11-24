import Foundation
import Testing

@testable import SunsetCredentials

/// Files made to hurt (roadmap 0095 D, white paper 9): what a program or a person hands Sunset to read is untrusted. Each of these is read
/// or refused in bounded work, says what it read, and invents nothing.
@Suite("Importing logins: hostile files")
struct LoginImportHostileTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    private let header = "name,url,username,password,note\n"

    @Test func `one cell of two million characters`() throws {
        let big = String(repeating: "x", count: 2_000_000)
        let imported = try LoginImport.read(header + "Big,https://a.example.com,u,\(big),\n", site: site)
        #expect(imported.entries.count == 1)
        #expect(imported.entries[0].field(named: "Password")?.value.count == 2_000_000)
    }

    @Test func `a million quotes with no end make one cell, not a hang or a crash`() {
        let file = header + "A,https://a.example.com,u,\"" + String(repeating: "\"", count: 1_000_000)
        // Read or refused, and at most the one row the file has.
        let count = (try? LoginImport.read(file, site: site))?.entries.count ?? 0
        #expect(count <= 1)
    }

    @Test func `twenty thousand logins are all read`() throws {
        var file = header
        for index in 0 ..< 20_000 { file += "S\(index),https://s\(index).example.com,u\(index),p\(index),\n" }
        let imported = try LoginImport.read(file, site: site)
        #expect(imported.entries.count == 20_000 && imported.skipped.isEmpty)
        #expect(imported.entries.last?.title == "S19999")
    }

    @Test func `a header of five thousand columns`() throws {
        let names = (0 ..< 5_000).map { "extra\($0)" } + ["username", "password"]
        let row = (0 ..< 5_000).map { _ in "" } + ["ada", "pw"]
        let imported = try LoginImport.read(
            names.joined(separator: ",") + "\n" + row.joined(separator: ",") + "\n",
            site: site
        )
        #expect(imported.entries.count == 1)
        #expect(
            imported.entries[0].field(named: "Username")?.value == "ada"
                && imported.entries[0].field(named: "Password")?.value == "pw"
        )
    }

    @Test func `rows shorter or longer than the header: missing cells are empty, extra ones are not read`() throws {
        let file =
            header + "Short,https://a.example.com,u\nLong,https://b.example.com,u,p,note,extra,more,even more\nJust\n"
        let imported = try LoginImport.read(file, site: site)
        // "Short" has a username and no password; "Long" is whole; "Just" has neither, so it is not a login.
        #expect(imported.entries.map(\.title) == ["Short", "Long"])
        #expect(imported.skipped == [LoginImport.Skipped(row: 4, reason: .empty)])
        #expect(imported.entries[1].note == "note")
    }

    @Test func `a header name given twice: the first column is the one read`() throws {
        let imported = try LoginImport.read("name,password,password\nA,first,second\n", site: site)
        #expect(imported.entries[0].field(named: "Password")?.value == "first")
    }

    @Test func `NUL bytes, other control characters and lone surrogates' replacements are kept as the cells' text`()
        throws
    {
        let file = header + "A\u{0}B,https://a.example.com,u\u{7}\u{1B},p\u{0}w,n\u{FFFD}\n"
        let entry = try #require(try LoginImport.read(file, site: site).entries.first)
        #expect(entry.title == "A\u{0}B" && entry.field(named: "Password")?.value == "p\u{0}w")
    }

    @Test func `an address that is not one is kept as text and never opened`() throws {
        for address in [
            "javascript:alert(1)", "file:///etc/passwd", "https://", "://", "\u{0}", "   ", "https://exa mple.com",
            "ht!tp://x"
        ] {
            let imported = try LoginImport.read(header + "A,\(address),u,p,\n", site: site)
            #expect(imported.entries.count == 1, "\(address.debugDescription)")
        }
    }

    @Test func `a file of only a header, or only blank lines, or only commas`() {
        #expect(throws: Never.self) { _ = try? LoginImport.read(header, site: site) }
        #expect((try? LoginImport.read(header, site: site))?.entries.isEmpty == true)
        #expect(throws: LoginImport.Failure.noLoginColumns) { try LoginImport.read("\n\n\n", site: site) }
        #expect(throws: LoginImport.Failure.noLoginColumns) { try LoginImport.read(",,,\n,,,\n", site: site) }
    }

    @Test func `the header row of a file with a byte-order mark is still a header`() throws {
        let imported = try LoginImport.read("\u{FEFF}" + header + "A,https://a.example.com,u,p,\n", site: site)
        #expect(imported.entries.count == 1 && imported.source == .chrome)
    }
}
