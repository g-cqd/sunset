import Foundation
import Testing

@testable import SunsetCredentials

/// Any field can be marked secret, or a secret kind shown plainly (the owner's notes n101–n104): kept with the entry, never
/// searched while secret; a record written before the mark reads as its kind says.
@Suite("A field marked secret")
struct EntryFieldSecretTests {
    @Test func `marked secret: hidden from search; unmarked: as its kind`() throws {
        var entry = EntryTemplate.login.makeEntry(title: "Bank")
        let user = try #require(entry.field(named: "Username")?.id)
        let password = try #require(entry.field(named: "Password")?.id)
        entry.set(user, "account-4471")
        #expect(EntrySearch.matching("4471", in: [entry]).count == 1)
        entry.markSecret(user, true)
        #expect(entry.field(named: "Username")?.isSecret == true)
        #expect(EntrySearch.matching("4471", in: [entry]).isEmpty, "a secret is never searched")
        entry.markSecret(password, false)
        #expect(entry.field(named: "Password")?.isSecret == false)
    }

    @Test func `a record written before the mark reads as its kind says`() throws {
        let old =
            #"{"id":"7C1A2B3D-0000-0000-0000-000000000001","name":"PIN","kind":{"concealed":{}},"value":"1234","constraints":[]}"#
        let field = try JSONDecoder().decode(EntryField.self, from: Data(old.utf8))
        #expect(field.markedSecret == nil && field.isSecret)
        let again = try JSONDecoder().decode(EntryField.self, from: JSONEncoder().encode(field))
        #expect(again == field)
    }

    @Test func `a field renamed and given another kind keeps its value`() throws {
        var entry = EntryTemplate.login.makeEntry(title: "Shop")
        let user = try #require(entry.field(named: "Username")?.id)
        entry.set(user, "ada@example.com")
        entry.rename(user, to: "Email address")
        entry.changeKind(user, to: .email, keepingOld: true)
        let field = try #require(entry.field(named: "Email address"))
        #expect(field.kind == .email && field.value == "ada@example.com")
    }
}
