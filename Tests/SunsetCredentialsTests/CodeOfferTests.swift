import Foundation
import Testing

@testable import SunsetCredentials

/// What a page's code field is offered (roadmap 0094 F): the codes of the entries for its site that have one (any entry,
/// not only logins); an entry whose code field holds nothing that reads is left out.
@Suite("Codes a page is offered")
struct CodeOfferTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    private func entry(_ title: String, website: String, code: String) throws -> VaultEntry {
        var entry = EntryTemplate.login.makeEntry(title: title)
        entry.set(try #require(entry.field(named: "Website")?.id), website)
        entry.set(try #require(entry.field(named: "One-Time Code")?.id), code)
        return entry
    }

    @Test func `the site's entries with a code, each with its code now; one without, or another site, none`() throws {
        let secret = Base32.encode(Data("12345678901234567890".utf8)).replacing("=", with: "")
        let good = try entry("Example", website: "https://example.com", code: secret)
        let empty = try entry("Empty", website: "https://example.com", code: "")
        let other = try entry("Other", website: "https://other.org", code: secret)
        let page = URL(string: "https://login.example.com/verify")
        let offered = CodeOffer.offered([good, empty, other], for: page, site: site)
        #expect(offered.map(\.entry.title) == ["Example"])
        let at = Date(timeIntervalSince1970: 59)
        #expect(offered.first?.field.code(at: at) == "287082")
    }
}
