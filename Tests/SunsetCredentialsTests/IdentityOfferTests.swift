import Foundation
import Testing

@testable import SunsetCredentials

/// What a page's contact or address field is offered (roadmap 0094, t103): every Identity with something to fill, by
/// title; its values by the autofill token of the field each goes in; an Address of one piece, from before the template
/// had its parts, is not filled.
@Suite("Identities a page is offered")
struct IdentityOfferTests {
    private func identity(_ title: String, _ values: [String: String]) throws -> VaultEntry {
        var entry = EntryTemplate.identity.makeEntry(title: title)
        for (name, value) in values {
            entry.set(try #require(entry.field(named: name)?.id), value)
        }
        return entry
    }

    @Test func `identities with something to fill, by title; each value by its field's token`() throws {
        let home = try identity(
            "Home",
            [
                "First Name": "Ada", "Last Name": "Lovelace", "Email": "ada@example.com", "Phone": "+44 20 7946 0000",
                "Street": "1 Road\nFlat 2\n", "City": "London", "Postal Code": "N1 9GU", "Region": "England",
                "Country": "GB"
            ]
        )
        let work = try identity("Work", ["Email": " ada@engines.example "])
        let blank = EntryTemplate.identity.makeEntry(title: "Blank")
        let login = EntryTemplate.login.makeEntry(title: "A login")
        let offers = IdentityOffer.offered([work, blank, login, home])
        #expect(offers.map(\.entry.title) == ["Home", "Work"])
        #expect(
            offers.first?.values == [
                "given-name": "Ada", "family-name": "Lovelace", "name": "Ada Lovelace", "email": "ada@example.com",
                "tel": "+44 20 7946 0000", "street-address": "1 Road\nFlat 2", "address-line1": "1 Road",
                "address-line2": "Flat 2", "address-level2": "London", "postal-code": "N1 9GU",
                "address-level1": "England", "country": "GB"
            ]
        )
        #expect(offers.last?.values == ["email": "ada@engines.example"] && offers.last?.detail == "ada@engines.example")
    }

    @Test func `an Address of one piece, from before the template had its parts, is not filled`() throws {
        var old = EntryTemplate.identity.makeEntry(title: "Old")
        let section = try #require(old.sections.first?.id)
        _ = old.add(EntryField(name: "Address", kind: .address, value: "1 Road\nLondon N1 9GU"), to: section)
        #expect(IdentityOffer.offered([old]).isEmpty)
        old.set(try #require(old.field(named: "First Name")?.id), "Ada")
        #expect(IdentityOffer.offered([old]).first?.values == ["given-name": "Ada", "name": "Ada"])
        #expect(IdentityOffer.offered([old]).first?.detail == "Ada")
    }
}
