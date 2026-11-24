import Foundation
import Testing

@testable import SunsetCredentials

/// Bitwarden's JSON made to hurt (roadmap 0095 E, white paper 9): a file is untrusted. Each is read or refused in bounded work, says what
/// it read, and invents nothing.
@Suite("Importing Bitwarden's JSON: hostile files")
struct BitwardenImportHostileTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    private func read(_ text: String) -> LoginImport? {
        try? LoginImport.readBitwarden(text, site: site)
    }

    private let login = #"{"type": 1, "name": "A", "login": {"username": "u", "password": "p"}}"#

    @Test func `nesting past the limit is refused, whatever the depth, without a crash`() {
        for depth in [33, 100, 600, 100_000] {
            let nested = String(repeating: "[", count: depth) + String(repeating: "]", count: depth)
            #expect(throws: LoginImport.Failure.notAnExport) {
                try LoginImport.readBitwarden(#"{"items": [\#(nested)]}"#, site: self.site)
            }
        }
    }

    @Test func `a key twice is refused: two answers to one question are not an export`() {
        #expect(throws: LoginImport.Failure.notAnExport) {
            try LoginImport.readBitwarden(#"{"items": [], "items": []}"#, site: site)
        }
        #expect(throws: LoginImport.Failure.notAnExport) {
            try LoginImport.readBitwarden(#"{"items": [{"type": 1, "type": 2, "name": "x"}]}"#, site: self.site)
        }
    }

    @Test
    func `the wrong type of value never stops the read: it is the item that is left out or the field that is empty`()
        throws
    {
        let file = """
            {"items": [
              {"type": "1", "name": "string type", "login": {}},
              {"type": 1.5, "name": "fraction type"},
              {"type": 1, "name": 12345, "login": {"username": 7, "password": ["x"], "uris": "no", "totp": {"a": 1}}},
              {"type": 1, "name": null, "login": [1, 2], "notes": {"a": 1}, "favorite": "yes", "folderId": 3, "fields": "no"},
              {"type": 3, "name": "card", "card": {"number": 4111111111111111, "expMonth": 4.5, "expYear": []}},
              null, 42, "text", [], {"type": 99}, {}
            ]}
            """
        let imported = try #require(read(file))
        // The item named by a number is kept, titled by its digits; the ones with no usable kind are left out and counted.
        #expect(imported.entries.map(\.title) == ["12345", "", "card"])
        #expect(imported.skipped.map(\.row) == [1, 2, 6, 7, 8, 9, 10, 11])
        #expect(imported.entries[2].field(named: "Number")?.value == "4111111111111111")
    }

    @Test func `a byte-order mark in front of the file is the file's, not a syntax error`() throws {
        let imported = try LoginImport.readBitwarden("\u{FEFF}" + #"{"items": [\#(login)]}"#, site: site)
        #expect(imported.entries.count == 1)
    }

    @Test func `a lone surrogate escape, a bad escape, a control character in a string: refused`() {
        for text in [
            #"{"items": [{"type": 1, "name": "\ud800"}]}"#, #"{"items": [{"type": 1, "name": "\q"}]}"#,
            "{\"items\": [{\"type\": 1, \"name\": \"a\u{1}b\"}]}"
        ] {
            #expect(throws: LoginImport.Failure.notAnExport) { try LoginImport.readBitwarden(text, site: self.site) }
        }
    }

    @Test func `numbers past any range are an item that is not understood, not a crash`() {
        for number in ["1e400", "-1e400", "99999999999999999999999999999999", "0.1e-400", "-0"] {
            let imported = read(#"{"items": [{"type": \#(number), "name": "x"}, \#(login)]}"#)
            #expect(imported?.entries.map(\.title) == ["A"], "\(number)")
        }
    }

    @Test func `a folder that does not exist, a folder with no name, a folder listed twice`() throws {
        let file =
            #"{"folders": [{"id": "a", "name": ""}, {"id": "b"}, {"id": "c", "name": "One"}, {"id": "c", "name": "Two"}], "items": ["#
            + #"{"type": 1, "name": "x", "folderId": "zzz", "login": {}}, {"type": 1, "name": "y", "folderId": "a", "login": {}}, "#
            + #"{"type": 1, "name": "z", "folderId": "c", "login": {}}]}"#
        let imported = try #require(read(file))
        #expect(
            imported.entries.map(\.folder) == [nil, nil, "Two"],
            "the last of two with one id is the one; none with no name"
        )
    }

    @Test func `fifty thousand items are all read`() throws {
        let items = (0 ..< 50_000)
            .map { #"{"type": 1, "name": "S\#($0)", "login": {"username": "u\#($0)", "password": "p"}}"# }
        let imported = try LoginImport.readBitwarden(#"{"items": [\#(items.joined(separator: ","))]}"#, site: site)
        #expect(imported.entries.count == 50_000 && imported.entries.last?.title == "S49999")
    }

    @Test func `a string of five million characters, a thousand custom fields`() throws {
        let big = String(repeating: "x", count: 5_000_000)
        let fields = (0 ..< 1_000).map { #"{"name": "f\#($0)", "value": "v", "type": 0}"# }.joined(separator: ",")
        let file =
            #"{"items": [{"type": 1, "name": "A", "notes": "\#(big)", "fields": [\#(fields)], "login": {"username": "u", "password": "p"}}]}"#
        let imported = try LoginImport.readBitwarden(file, site: site)
        #expect(imported.entries[0].note.count == 5_000_000)
        #expect(imported.entries[0].sections.flatMap(\.fields).count > 1_000)
    }

    @Test func `a totp that is a link, a secret, a secret with spaces and dashes, or nothing a code can be made of`()
        throws
    {
        for (totp, readable) in [
            ("otpauth://totp/x?secret=JBSWY3DPEHPK3PXP", true), ("JBSWY3DPEHPK3PXP", true),
            ("jbsw y3dp-ehpk 3pxp", true),
            ("steam://JBSWY3DPEHPK3PXP", true), ("", false), ("not a secret 189!", false),
            ("otpauth://totp/x?secret=", false)
        ] {
            let file =
                #"{"items": [{"type": 1, "name": "A", "login": {"username": "u", "password": "p", "totp": "\#(totp)"}}]}"#
            let imported = try LoginImport.readBitwarden(file, site: site)
            let code = imported.entries[0].field(named: "One-Time Code")?.value ?? ""
            #expect(code.isEmpty != readable, "\(totp.debugDescription)")
            #expect(imported.warnings.isEmpty == (readable || totp.isEmpty), "\(totp.debugDescription)")
        }
    }
}
