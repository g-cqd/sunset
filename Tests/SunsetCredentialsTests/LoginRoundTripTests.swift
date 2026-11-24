import AemiTestKit
import Foundation
import Testing

@testable import SunsetCredentials

/// What the vault exports is what the vault imports again, field for field (roadmap 0095 D): a property over generated logins whose
/// passwords, usernames, titles and notes hold every awkward character. A password that comes back changed is a password that no longer works.
@Suite("Logins: exported, then imported")
struct LoginRoundTripTests {
    static let alphabet: [Character] = [
        "a", "Z", "0", " ", ",", "\"", "\n", "\r", "\r\n", "\t", "=", "+", "-", "@", "'", "é", "😀", "я", ";", "\\", "/",
        "<", "&"
    ]
    static let websites = [
        "", "https://example.com", "https://a.example.org/x?y=1&z=2", "http://localhost:8080/",
        "https://sub.mail.example.co.uk/in"
    ]
    static let codes = [
        "", "otpauth://totp/Mail:ada?secret=JBSWY3DPEHPK3PXP&issuer=Mail",
        "otpauth://totp/x?secret=GEZDGNBVGY3TQOJQ&digits=8&period=60&algorithm=SHA256"
    ]

    struct Login: Equatable, Sendable, CustomStringConvertible {
        var title: String
        var username: String
        var password: String
        var website: String
        var note: String
        var code: String
        var description: String {
            "Login(title: \(title.debugDescription), user: \(username.debugDescription), password: \(password.debugDescription), note: \(note.debugDescription))"
        }
    }

    static var logins: AnyGenerator<[Login]> {
        let text = Gen.string(maxLength: 10, alphabet: alphabet)
        let one = AnyGenerator<Login>(
            generate: { rng in
                var login = Login(
                    title: text.generate(using: &rng),
                    username: text.generate(using: &rng),
                    password: text.generate(using: &rng),
                    website: websites[rng.uniform(websites.count)],
                    note: text.generate(using: &rng),
                    code: codes[rng.uniform(codes.count)]
                )
                // A login has a title and a password: an empty one is a different thing (the title becomes its site; no password and no
                // username is not a login at all).
                if login.title.isEmpty { login.title = "T" }
                if login.password.isEmpty { login.password = "p" }
                return login
            },
            shrink: { _ in [] }
        )
        return Gen.array(of: one, maxCount: 6)
    }

    private func entry(_ login: Login) -> VaultEntry {
        var entry = EntryTemplate.login.makeEntry(title: login.title)
        for (name, value) in [
            ("Website", login.website), ("Username", login.username), ("Password", login.password),
            ("One-Time Code", login.code)
        ] {
            if let field = entry.field(named: name)?.id { entry.set(field, value) }
        }
        entry.note = login.note
        return entry
    }

    private func site(_ host: String) -> String? {
        host.split(separator: ".").suffix(2).joined(separator: ".")
    }

    @Test func `every field of every login comes back exactly as it was`() {
        forAll(Self.logins, count: 500, seed: .named("login.roundtrip")) { logins in
            let exported = LoginExport.csv(of: logins.map(self.entry))
            guard let back = try? LoginImport.read(exported.text, site: self.site) else { return logins.isEmpty }
            guard back.entries.count == logins.count, back.skipped.isEmpty, back.warnings.isEmpty else { return false }
            return zip(back.entries, logins)
                .allSatisfy { got, want in
                    got.title == want.title && got.note == want.note
                        && got.field(named: "Username")?.value ?? "" == want.username
                        && got.field(named: "Password")?.value ?? "" == want.password
                        && got.field(named: "Website")?.value ?? "" == want.website
                        && got.field(named: "One-Time Code")?.value ?? "" == want.code
                }
        }
    }
}
