import Foundation
import Testing

@testable import SunsetCredentials

/// One Import for every file (roadmap 0095): the reader is chosen by what the file is, not by what it is called: JSON that opens with an
/// object or a list is Bitwarden's export, anything else is CSV. A file renamed, or with no extension, is still read as what it is.
@Suite("Importing: which reader a file is for")
struct ImportFileSniffTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    private let csv = "name,url,username,password,note\nA,https://a.example.com,u,p,\n"
    private let json = #"{"items": [{"type": 1, "name": "A", "login": {"username": "u", "password": "p"}}]}"#

    @Test func `CSV is read as CSV, JSON as Bitwarden's, whatever the file is called`() throws {
        #expect(try LoginImport.readFile(csv, site: site).source == .chrome)
        #expect(try LoginImport.readFile(json, site: site).source == .bitwarden)
    }

    @Test func `a byte-order mark, spaces and blank lines in front do not change which it is`() throws {
        #expect(try LoginImport.readFile("\u{FEFF}" + json, site: site).source == .bitwarden)
        #expect(try LoginImport.readFile("\n \t\r\n" + json, site: site).source == .bitwarden)
        #expect(try LoginImport.readFile("\u{FEFF}\n" + csv, site: site).source == .chrome)
    }

    @Test func `a list at the top is JSON that is not an export, not a CSV with a strange header`() {
        #expect(throws: LoginImport.Failure.notAnExport) { try LoginImport.readFile("[1, 2]", site: site) }
        #expect(throws: LoginImport.Failure.notAnExport) { try LoginImport.readFile("{ not json", site: site) }
    }

    @Test func `nothing at all is a file with no logins`() {
        #expect(throws: LoginImport.Failure.noLoginColumns) { try LoginImport.readFile("", site: site) }
        #expect(throws: LoginImport.Failure.noLoginColumns) { try LoginImport.readFile(" \n\n", site: site) }
    }
}
