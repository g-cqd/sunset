import Testing

@testable import SunsetCredentials

/// Whether a field's value still fits when its kind changes (the owner, 2026-11-23, t334): a change it does not fit is asked
/// about first, and the value can be kept. An empty value fits every kind.
@Suite("A value and a kind")
struct FieldKindFitTests {
    @Test func `values that fit their new kind`() {
        let fits: [(FieldKind, String)] = [
            (.text, "ada"), (.concealed, "s3cret!"), (.multiline, "two\nlines"), (.number, "42.5"), (.money, "-12.30"),
            (.date, "2030-04-30"), (.monthYear, "2030-04"), (.time, "09:30"), (.url, "https://example.com/a"),
            (.url, "example.com"), (.email, "ada@example.com"), (.phone, "+33 (0)1 23-45"), (.toggle, "true"),
            (.choice(["a", "b"]), "b"), (.multipleChoice(["a", "b"]), "a, b"), (.cardNumber, "4111 1111-1111 1111"),
            (.oneTimeCode, "JBSWY3DPEHPK3PXP"), (.sshKey, "ssh-ed25519 AAAA\nmore"), (.address, "1 Rue\nParis"),
            (.date, "")
        ]
        for (kind, value) in fits { #expect(kind.fit(value) == .fits, "\(kind) \(value.debugDescription)") }
    }

    @Test func `values that would be lost, each said why`() {
        let loses: [(FieldKind, String)] = [
            (.text, "two\nlines"), (.number, "forty"), (.date, "next week"), (.monthYear, "2030-04-30"),
            (.time, "noon"), (.url, "not a site"), (.email, "ada"), (.phone, "call me"), (.toggle, "maybe"),
            (.choice(["a", "b"]), "c"), (.multipleChoice(["a"]), "a, z"), (.cardNumber, "4111 x"),
            (.oneTimeCode, "not a secret!")
        ]
        for (kind, value) in loses {
            guard case .loses(let why) = kind.fit(value) else {
                Issue.record("\(kind) \(value.debugDescription) should not fit")
                continue
            }
            #expect(!why.isEmpty)
        }
    }

    @Test func `a value that does not fit is kept in a new field when asked, or left as written`() throws {
        var entry = EntryTemplate.login.makeEntry(title: "Bank")
        let user = try #require(entry.field(named: "Username")?.id)
        entry.set(user, "ada")
        var kept = entry
        let made = kept.changeKind(user, to: .date, keepingOld: true)
        let added = try #require(made)
        let fields = kept.sections.flatMap(\.fields)
        let at = try #require(fields.firstIndex { $0.id == user })
        #expect(fields[at].kind == .date && fields[at].value.isEmpty)
        #expect(
            fields[at + 1].id == added && fields[at + 1].name == "Username (before)" && fields[at + 1].value == "ada"
        )
        var left = entry
        #expect(left.changeKind(user, to: .date, keepingOld: false) == nil)
        #expect(left.field(named: "Username")?.value == "ada" && left.field(named: "Username")?.kind == .date)
        var fitting = entry
        #expect(fitting.changeKind(user, to: .multiline, keepingOld: true) == nil, "nothing to keep: no field added")
    }

    @Test func `a secret's old value is kept secret`() throws {
        var entry = EntryTemplate.login.makeEntry(title: "Bank")
        let password = try #require(entry.field(named: "Password")?.id)
        entry.set(password, "s3cret!")
        let made = entry.changeKind(password, to: .number, keepingOld: true)
        let added = try #require(made)
        #expect(entry.sections.flatMap(\.fields).first { $0.id == added }?.isSecret == true)
    }

    @Test func `a sheet saved unchanged changes nothing; secrecy follows the kind unless set apart`() throws {
        let entry = EntryTemplate.login.makeEntry(title: "Bank")
        let user = try #require(entry.field(named: "Username"))
        var same = entry
        same.apply(name: user.name, kind: user.kind, secret: user.isSecret, keepingOld: false, to: user.id)
        #expect(same == entry)
        var password = entry
        password.apply(name: "PIN", kind: .concealed, secret: true, keepingOld: false, to: user.id)
        let pin = try #require(password.field(named: "PIN"))
        #expect(pin.isSecret && pin.markedSecret == nil, "a password is secret by its kind")
        var plain = entry
        plain.apply(name: user.name, kind: user.kind, secret: true, keepingOld: false, to: user.id)
        #expect(plain.field(named: "Username")?.markedSecret == true)
    }
}
