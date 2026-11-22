import Foundation
import Testing

@testable import SunsetCredentials

/// What a password sent asks (roadmap 0094 D): nothing when the vault already has it for the site; to update the
/// password of the entry with that username; else to save a new login, titled for its site. Asked once a page; never
/// for a site the person said never to.
@Suite("Offering to save a sign-in")
struct LoginSaveTests {
    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    private func login(_ user: String, _ password: String, _ website: String = "https://example.com") throws
        -> VaultEntry
    {
        var entry = EntryTemplate.login.makeEntry(title: "Example")
        for (name, value) in [("Website", website), ("Username", user), ("Password", password)] {
            entry.set(try #require(entry.field(named: name)?.id), value)
        }
        return entry
    }

    @Test func `known: nothing; a new password for a known username: update; a new username: save`() throws {
        let origin = try #require(URL(string: "https://accounts.example.com"))
        let kept = try login("ada", "pw1")
        #expect(
            LoginSave.offer(
                for: SentLoginValues(origin: origin, username: "ada", password: "pw1"),
                in: [kept],
                never: [],
                site: site
            ) == nil
        )
        let update = LoginSave.offer(
            for: SentLoginValues(origin: origin, username: "ada", password: "pw2"),
            in: [kept],
            never: [],
            site: site
        )
        #expect(update == .update(kept.id))
        let new = LoginSave.offer(
            for: SentLoginValues(origin: origin, username: "bob", password: "pw"),
            in: [kept],
            never: [],
            site: site
        )
        #expect(new == .save)
        #expect(
            LoginSave.offer(
                for: SentLoginValues(origin: origin, username: "bob", password: "pw"),
                in: [],
                never: ["example.com"],
                site: site
            ) == nil
        )
    }

    @Test func `a new login: titled for its site, its website the page's origin`() throws {
        let origin = try #require(URL(string: "https://accounts.example.com"))
        let entry = LoginSave.entry(for: SentLoginValues(origin: origin, username: "bob", password: "pw"), site: site)
        #expect(entry.title == "example.com" && entry.template == EntryTemplate.login.id)
        #expect(entry.field(named: "Website")?.value == "https://accounts.example.com")
        #expect(LoginMatch.credentials(of: entry) == LoginCredentials(username: "bob", password: "pw"))
    }
}
