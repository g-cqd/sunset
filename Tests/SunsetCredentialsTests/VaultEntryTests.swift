import Foundation
import Testing

@testable import SunsetCredentials

/// An entry's model (roadmap 0092 A, ADR-0092): sections of typed fields made from a template, free to differ from it; a
/// Markdown note, tags, a folder; kept as one sealed record.
@Suite("A vault entry")
struct VaultEntryTests {
    @Test func `the shipped templates, each with its fields; a login's password concealed, a card's number checked`()
        throws
    {
        let names = EntryTemplate.shipped.map(\.name)
        #expect(
            names == [
                "Login", "Card", "Identity", "Secure Note", "Licence", "SSH Key", "Wi-Fi", "Bank Account", "Passport",
                "API Key",
                "Server"
            ]
        )
        #expect(Set(EntryTemplate.shipped.map(\.id)).count == names.count, "each its own id")
        let fieldCounts = EntryTemplate.shipped.map { $0.sections.flatMap(\.fields).count }
        #expect(fieldCounts == [4, 5, 6, 0, 6, 3, 3, 5, 5, 5, 4], "every field of the table read")
        let server = EntryTemplate.server.makeEntry(title: "Box")
        #expect(server.field(named: "Port")?.constraints == [.range(1 ... 65_535)])
        #expect(EntryTemplate.shipped[6].sections[0].fields[2].kind == .choice(["WPA3", "WPA2", "WEP", "None"]))
        let login = EntryTemplate.login.makeEntry(title: "Example")
        let fields = login.sections.flatMap(\.fields)
        #expect(fields.map(\.kind) == [.text, .concealed, .url, .oneTimeCode])
        #expect(fields.filter(\.kind.isConcealed).map(\.name) == ["Password", "One-Time Code"])
        let card = EntryTemplate.card.makeEntry(title: "Bank")
        #expect(card.field(named: "Number")?.constraints.contains(.luhn) == true)
        #expect(card.template == EntryTemplate.card.id)
    }

    @Test func `fields are added, renamed, moved and removed; the entry keeps what its template did not have`() throws {
        var entry = EntryTemplate.login.makeEntry(title: "Example")
        let section = try #require(entry.sections.first?.id)
        let pin = entry.add(EntryField(name: "PIN", kind: .concealed), to: section)
        entry.rename(pin, to: "Door PIN")
        entry.move(pin, to: 0, in: section)
        #expect(entry.sections[0].fields.first?.name == "Door PIN")
        let url = try #require(entry.field(named: "Website")?.id)
        entry.remove(url)
        #expect(entry.field(named: "Website") == nil && entry.field(named: "Door PIN") != nil)
    }

    @Test func `constraints: required blocks a save, the others only warn`() throws {
        var entry = EntryTemplate.card.makeEntry(title: "Card")
        let number = try #require(entry.field(named: "Number")?.id)
        let expiry = try #require(entry.field(named: "Expiry")?.id)
        let now = Date(timeIntervalSince1970: 1_795_000_000)  // 2026-11
        entry.set(number, "4111 1111 1111 1112")
        entry.set(expiry, "2024-01")
        let problems = entry.problems(now: now)
        #expect(Set(problems.map(\.constraint)) == [.luhn, .inTheFuture])
        #expect(entry.blocksSave(now: now) == false)
        entry.set(number, "4111 1111 1111 1111")
        entry.set(expiry, "2030-04")
        #expect(entry.problems(now: now).isEmpty)
        var login = EntryTemplate.login.makeEntry(title: "")
        let user = try #require(login.field(named: "Username")?.id)
        login.constrain(user, [.required, .length(3 ... 8), .pattern("^[a-z]+$")])
        #expect(login.blocksSave(now: now), "required and empty")
        login.set(user, "AB")
        #expect(Set(login.problems(now: now).map(\.constraint)) == [.length(3 ... 8), .pattern("^[a-z]+$")])
        #expect(!login.blocksSave(now: now))
    }

    @Test func `numbers and their ranges; a choice among its options`() throws {
        var entry = VaultEntry(title: "Custom")
        let section = entry.addSection("Details")
        let age = entry.add(EntryField(name: "Floor", kind: .number, constraints: [.range(0 ... 40)]), to: section)
        let colour = entry.add(EntryField(name: "Colour", kind: .choice(["Red", "Blue"])), to: section)
        entry.set(age, "41")
        entry.set(colour, "Green")
        #expect(Set(entry.problems(now: .now).map(\.constraint)) == [.range(0 ... 40), .oneOf(["Red", "Blue"])])
        entry.set(age, "not a number")
        #expect(entry.problems(now: .now).contains { $0.constraint == .range(0 ... 40) })
    }

    @Test func `kept as JSON and read back the same`() throws {
        var entry = EntryTemplate.server.makeEntry(title: "Build box")
        entry.note = "# Access\nThrough the bastion."
        entry.tags = ["work", "infra"]
        entry.folder = "Servers"
        let data = try JSONEncoder().encode(entry)
        #expect(try JSONDecoder().decode(VaultEntry.self, from: data) == entry)
    }
}
