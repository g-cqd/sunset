import Foundation
import Testing

@testable import SunsetCredentials

/// What a page's card field is offered (roadmap 0094 F): every card of the vault with a number (cards are not tied to a
/// site), shown by its title and last four digits; its values as a form wants them.
@Suite("Cards a page is offered")
struct CardOfferTests {
    private func card(_ title: String, number: String, expiry: String = "2031-04", holder: String = "Ada Lovelace")
        throws -> VaultEntry
    {
        var entry = EntryTemplate.card.makeEntry(title: title)
        for (name, value) in [("Number", number), ("Expiry", expiry), ("Cardholder", holder), ("Security Code", "123")]
        {
            entry.set(try #require(entry.field(named: name)?.id), value)
        }
        return entry
    }

    @Test func `cards with a number, by title; their values; a login is not a card`() throws {
        let visa = try card("Visa", number: "4111 1111 1111 1111")
        let blank = EntryTemplate.card.makeEntry(title: "Blank")
        let login = EntryTemplate.login.makeEntry(title: "Login")
        let offers = CardOffer.offered([login, blank, visa])
        #expect(offers.map(\.entry.title) == ["Visa"])
        let values = try #require(offers.first?.values)
        #expect(values.number == "4111111111111111" && values.name == "Ada Lovelace" && values.code == "123")
        #expect(values.month == "04" && values.year == "2031")
        #expect(offers.first?.lastFour == "1111")
    }

    @Test func `an expiry however written: 2031-04, 04/31, 4/2031`() throws {
        for expiry in ["2031-04", "04/31", "4/2031", "04 / 2031"] {
            let values = try #require(
                CardOffer.offered([try card("C", number: "4111111111111111", expiry: expiry)]).first?.values
            )
            #expect(values.month == "04" && values.year == "2031", "\(expiry)")
        }
    }
}
