import AemiJSONCore
import AemiTestKit
import Foundation
import OrderedCollections

@testable import SunsetCredentials

/// A Bitwarden export as the tests build it: the items of any of the four kinds, written as JSON by AemiJSON, and what each must become in
/// the vault, worked out here from the model and not by the importer's own code. Strings hold every awkward character, JSON escapes included.
struct BitwardenDocument: Sendable, CustomStringConvertible {
    struct Item: Sendable {
        enum Kind: Int, Sendable {
            case login = 1
            case secureNote, card, identity
        }
        var kind: Kind
        var name: String
        var notes: String
        var favorite: Bool
        var folder: String?
        /// What an item holds: usernames, passwords, numbers, names, in the order its kind reads them.
        var texts: [String]
        var month: Int
        var year: Int
        var hiddenField: String
    }

    var items: [Item]
    var folders: [String]

    var description: String {
        "BitwardenDocument(\(items.map { "\($0.kind) \($0.name.debugDescription)" }))"
    }

    static let alphabet: [Character] = [
        "a", "Z", "0", " ", ",", "\"", "\n", "\r", "\r\n", "\t", "\\", "/", "<", "&", "'", "é", "😀", "я", "\u{7}",
        "\u{1F}", "\u{2028}", "="
    ]

    /// Documents of up to six items, a couple of folders; shrinks by dropping items.
    static var generator: AnyGenerator<BitwardenDocument> {
        let text = Gen.string(maxLength: 10, alphabet: alphabet)
        return AnyGenerator(
            generate: { rng in
                let folders = ["Work", "Family \u{1F600}"]
                let items = (0 ..< rng.uniform(7))
                    .map { _ -> Item in
                        Item(
                            kind: Item.Kind(rawValue: 1 + rng.uniform(4)) ?? .login,
                            name: "N" + text.generate(using: &rng),
                            notes: text.generate(using: &rng),
                            favorite: rng.uniform(2) == 0,
                            folder: rng.uniform(3) == 0 ? nil : folders[rng.uniform(folders.count)],
                            texts: (0 ..< 6).map { _ in "t" + text.generate(using: &rng) },
                            month: 1 + rng.uniform(12),
                            year: 2000 + rng.uniform(100),
                            hiddenField: text.generate(using: &rng)
                        )
                    }
                return BitwardenDocument(items: items, folders: folders)
            },
            shrink: { document in
                document.items.indices.map { index in
                    var smaller = document
                    smaller.items.remove(at: index)
                    return smaller
                }
            }
        )
    }

    // MARK: JSON

    var json: JSONValue {
        .object([
            "encrypted": .bool(false),
            "folders": .array(
                folders.enumerated().map { .object(["id": .string("f\($0.offset)"), "name": .string($0.element)]) }
            ),
            "items": .array(items.enumerated().map { item($1, id: $0) })
        ])
    }

    private func item(_ item: Item, id: Int) -> JSONValue {
        let text = item.texts.map { JSONValue.string($0) }
        var object: [String: JSONValue] = [
            "id": .string("id\(id)"), "organizationId": .null, "type": .int(Int64(item.kind.rawValue)),
            "reprompt": .int(0),
            "name": .string(item.name), "notes": .string(item.notes), "favorite": .bool(item.favorite),
            "folderId": item.folder.flatMap { folder in folders.firstIndex(of: folder).map { .string("f\($0)") } }
                ?? .null,
            "fields": .array([
                .object(["name": .string("Hidden"), "value": .string(item.hiddenField), "type": .int(1)]),
                .object(["name": .string("Shown"), "value": .string(item.texts[5]), "type": .int(0)])
            ]),
            "deletedDate": .null, "collectionIds": .null
        ]
        switch item.kind {
            case .login:
                object["login"] = .object([
                    "uris": .array([
                        .object([
                            "match": .null, "uri": .string("https://a.example.com/" + item.texts[2].filter(\.isLetter))
                        ])
                    ]),
                    "username": text[0], "password": text[1], "totp": .null
                ])
            case .secureNote: object["secureNote"] = .object(["type": .int(0)])
            case .card:
                object["card"] = .object([
                    "cardholderName": text[0], "brand": text[1], "number": text[2],
                    "expMonth": .string(String(item.month)),
                    "expYear": .string(String(item.year)), "code": text[3]
                ])
            case .identity:
                object["identity"] = .object([
                    "firstName": text[0], "lastName": text[1], "email": text[2], "phone": text[3], "address1": text[4],
                    "company": text[5], "title": .null, "middleName": .null, "address2": .null, "address3": .null,
                    "city": .null,
                    "state": .null, "postalCode": .null, "country": .null, "ssn": .null, "username": .null,
                    "passportNumber": .null,
                    "licenseNumber": .null
                ])
        }
        return .object(.init(uniqueKeysWithValues: object.sorted { $0.key < $1.key }))
    }

    var bytes: [UInt8] {
        (try? json.encodedBytes()) ?? []
    }

    var text: String {
        String(decoding: bytes, as: UTF8.self)
    }

    // MARK: What it must become

    /// What a faithful importer makes of one item.
    struct Expectation: Sendable {
        var template: UUID?
        var title: String
        var folder: String?
        var favorite: Bool
        var note: String
        var fields: [String: String]
    }

    var expected: [Expectation] {
        items.map { item in
            var fields: [String: String] = ["Hidden": item.hiddenField, "Shown": item.texts[5]]
            let template: UUID?
            switch item.kind {
                case .login:
                    template = EntryTemplate.login.id
                    fields["Username"] = item.texts[0]
                    fields["Password"] = item.texts[1]
                    fields["Website"] = "https://a.example.com/" + item.texts[2].filter(\.isLetter)
                case .secureNote: template = EntryTemplate.secureNote.id
                case .card:
                    template = EntryTemplate.card.id
                    fields["Cardholder"] = item.texts[0]
                    fields["Brand"] = item.texts[1]
                    fields["Number"] = item.texts[2]
                    fields["Security Code"] = item.texts[3]
                    fields["Expiry"] = String(format: "%04d-%02d", item.year, item.month)
                case .identity:
                    template = EntryTemplate.identity.id
                    fields["First Name"] = item.texts[0]
                    fields["Last Name"] = item.texts[1]
                    fields["Email"] = item.texts[2]
                    fields["Phone"] = item.texts[3]
                    fields["Address"] = item.texts[4]
                    fields["Company"] = item.texts[5]
            }
            return Expectation(
                template: template,
                title: item.name,
                folder: item.folder,
                favorite: item.favorite,
                note: item.notes,
                fields: fields
            )
        }
    }
}
