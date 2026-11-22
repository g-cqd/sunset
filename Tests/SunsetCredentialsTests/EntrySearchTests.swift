import Foundation
import Testing

@testable import SunsetCredentials

/// The Passwords section's search (roadmap 0092 E): an entry is found by its title, its fields' values, its tags, its
/// folder and its note, every word typed somewhere in it, in any case and accent; never by a secret's value.
@Suite("Searching the entries")
struct EntrySearchTests {
    private func login(_ title: String, user: String, password: String, site: String) throws -> VaultEntry {
        var entry = EntryTemplate.login.makeEntry(title: title)
        for (name, value) in [("Username", user), ("Password", password), ("Website", site)] {
            entry.set(try #require(entry.field(named: name)?.id), value)
        }
        return entry
    }

    @Test func `found by title, a field, a tag, the folder or the note; every word somewhere`() throws {
        var bank = try login("Banque Populaire", user: "ada@example.com", password: "hunter2", site: "https://bp.fr")
        bank.tags = ["money"]
        bank.folder = "Personal"
        bank.note = "Branch in Lyon"
        let mail = try login("Mail", user: "ada@example.com", password: "x", site: "https://mail.example.com")
        let all = [bank, mail]
        #expect(EntrySearch.matching("banque", in: all) == [bank], "case and accents aside")
        #expect(EntrySearch.matching("ada example", in: all).count == 2)
        #expect(EntrySearch.matching("lyon", in: all) == [bank] && EntrySearch.matching("money", in: all) == [bank])
        #expect(EntrySearch.matching("personal mail", in: all).isEmpty, "every word in the same entry")
        #expect(EntrySearch.matching("hunter2", in: all).isEmpty, "never a secret")
        #expect(EntrySearch.matching("  ", in: all) == all)
    }
}
