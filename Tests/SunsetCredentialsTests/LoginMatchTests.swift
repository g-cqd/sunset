import Foundation
import Testing

@testable import SunsetCredentials

/// Which entries a page is offered (roadmap 0094 B, ADR-0094): those whose website is the page's site (its registrable
/// domain), the page's exact host first; an entry for http only offered on http; a look-alike host never.
@Suite("Logins a page is offered")
struct LoginMatchTests {
    /// The registrable domain of a host, as the Public Suffix List would give it, for the hosts of these tests.
    private func site(_ host: String) -> String? {
        let parts = host.split(separator: ".")
        if host.hasSuffix(".co.uk") { return parts.suffix(3).joined(separator: ".") }
        return parts.count >= 2 ? parts.suffix(2).joined(separator: ".") : nil
    }

    private func login(_ title: String, _ site: String, user: String = "ada", password: String = "pw") throws
        -> VaultEntry
    {
        var entry = EntryTemplate.login.makeEntry(title: title)
        for (name, value) in [("Website", site), ("Username", user), ("Password", password)] {
            entry.set(try #require(entry.field(named: name)?.id), value)
        }
        return entry
    }

    @Test func `the page's site, the exact host first; another site or a look-alike never`() throws {
        let exact = try login("Accounts", "https://accounts.example.com")
        let sibling = try login("Example", "example.com/login")
        let other = try login("Other", "https://example.org")
        let lookalike = try login("Fake", "https://example.com.evil.net")
        let bank = try login("Bank", "https://bank.co.uk")
        let all = [sibling, other, exact, lookalike, bank]
        let offered = LoginMatch.offered(all, for: URL(string: "https://accounts.example.com/signin"), site: site)
        #expect(offered.map(\.title) == ["Accounts", "Example"])
        #expect(LoginMatch.offered(all, for: URL(string: "https://other.co.uk/"), site: site).isEmpty)
        #expect(
            LoginMatch.offered(all, for: URL(string: "https://www.bank.co.uk/"), site: site).map(\.title) == ["Bank"]
        )
    }

    @Test func `an entry saved for https is not offered on http; one for http is offered on both; no site, no offer`()
        throws
    {
        let secure = try login("Secure", "https://example.com")
        let plain = try login("Plain", "http://intranet.example.com")
        let all = [secure, plain]
        #expect(LoginMatch.offered(all, for: URL(string: "http://example.com"), site: site).map(\.title) == ["Plain"])
        #expect(LoginMatch.offered(all, for: URL(string: "https://example.com"), site: site).count == 2)
        #expect(LoginMatch.offered(all, for: URL(string: "about:blank"), site: site).isEmpty)
        #expect(LoginMatch.offered(all, for: nil, site: site).isEmpty)
    }

    @Test func `what is filled: its username and password; an entry without a password is not a login`() throws {
        let entry = try login("A", "example.com", user: "ada", password: "s3cret")
        #expect(LoginMatch.credentials(of: entry) == LoginCredentials(username: "ada", password: "s3cret"))
        var note = EntryTemplate.secureNote.makeEntry(title: "N")
        note.addSection("x")
        #expect(LoginMatch.credentials(of: note) == nil)
    }

    @Test func `filled on load only over https, with the site's one login, saved for the page's very origin`() throws {
        let page = try #require(URL(string: "https://accounts.example.com/signin"))
        func filled(_ entries: [VaultEntry], at page: URL) -> String? {
            LoginMatch.autoFilled(entries, for: page, site: site)?.title
        }
        let exact = try login("Accounts", "https://accounts.example.com/login")
        #expect(filled([exact], at: page) == "Accounts")
        #expect(filled([exact, try login("Other", "https://example.org")], at: page) == "Accounts")
        // A second account of the site, even for another host of it: the person chooses.
        #expect(filled([exact, try login("Second", "https://accounts.example.com", user: "bob")], at: page) == nil)
        #expect(filled([exact, try login("Sibling", "https://www.example.com")], at: page) == nil)
        // Only one, but not for this very origin: another host, scheme or port; or a website without a scheme.
        for website in ["https://www.example.com", "https://accounts.example.com:8443", "accounts.example.com"] {
            let expected = website == "accounts.example.com" ? "Only" : nil
            #expect(filled([try login("Only", website)], at: page) == expected, "\(website)")
        }
        let insecure = try #require(URL(string: "http://accounts.example.com/signin"))
        #expect(filled([try login("Plain", "http://accounts.example.com")], at: insecure) == nil, "never over http")
        #expect(filled([try login("Plain", "http://accounts.example.com")], at: page) == nil, "saved for http")
        let port = try #require(URL(string: "https://accounts.example.com:443/"))
        #expect(filled([exact], at: port) == "Accounts", "443 is https's own port")
    }
}
