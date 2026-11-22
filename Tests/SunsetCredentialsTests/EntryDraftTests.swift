import Foundation
import Testing

@testable import SunsetCredentials

/// An entry being edited (roadmap 0092 B): what it changed, whether it can be saved, the kinds a field can be added as,
/// and a password generated into a concealed field.
@Suite("An entry being edited")
struct EntryDraftTests {
    @Test func `changed once it differs from what is kept; saved only without a blocking problem`() throws {
        let kept = EntryTemplate.login.makeEntry(title: "Bank")
        var draft = EntryDraft(kept)
        #expect(!draft.isChanged && draft.canSave(now: .now) == false, "nothing to save")
        draft.entry.title = "Bank (new)"
        #expect(draft.isChanged && draft.canSave(now: .now))
        let user = try #require(draft.entry.field(named: "Username")?.id)
        draft.entry.constrain(user, [.required])
        #expect(!draft.canSave(now: .now), "a required field left empty")
        draft.revert()
        #expect(draft.entry == kept && !draft.isChanged)
    }

    @Test func `a field added by kind, named for it; a password generated into a concealed field`() throws {
        var draft = EntryDraft(VaultEntry(title: "Custom"))
        let added = draft.add(.concealed)
        #expect(draft.entry.sections.count == 1, "a section made for it")
        #expect(draft.entry.sections[0].fields.map(\.name) == ["Password"])
        draft.generate(into: added, recipe: PasswordRecipe(length: 24, classes: [.lower, .upper, .digit, .symbol]))
        #expect(draft.entry.sections[0].fields[0].value.count == 24)
        let text = draft.add(.text)
        #expect(draft.entry.sections[0].fields.map(\.name) == ["Password", "Text"] && text != added)
        #expect(
            EntryDraft.addable.map(\.name) == [
                "Text", "Password", "One-Time Code", "Website", "Email", "Phone", "Number", "Date", "Note"
            ]
        )
    }

    @Test func `fields reordered within their section, as a list's move gives them`() throws {
        var draft = EntryDraft(EntryTemplate.login.makeEntry(title: "Bank"))
        let section = try #require(draft.entry.sections.first?.id)
        draft.move(in: section, from: IndexSet(integer: 1), to: 0)
        #expect(draft.entry.sections[0].fields.map(\.name) == ["Password", "Username", "Website", "One-Time Code"])
        draft.move(in: section, from: IndexSet([0, 1]), to: 4)
        #expect(draft.entry.sections[0].fields.map(\.name) == ["Website", "One-Time Code", "Password", "Username"])
        #expect(draft.isChanged)
    }

    @Test func `a code read from a QR code sets up the entry: its code field, and the title and username left empty`()
        throws
    {
        let code = try OneTimeCodeURI("otpauth://totp/GitHub:ada?secret=JBSWY3DPEHPK3PXP&issuer=GitHub")
        var login = EntryDraft(EntryTemplate.login.makeEntry(title: ""))
        login.setUp(code)
        #expect(login.entry.title == "GitHub" && login.entry.field(named: "Username")?.value == "ada")
        #expect(login.entry.field(named: "One-Time Code")?.value == code.uri)
        var named = EntryDraft(EntryTemplate.login.makeEntry(title: "Work"))
        named.setUp(code)
        #expect(named.entry.title == "Work", "a title already there is kept")
        var note = EntryDraft(EntryTemplate.secureNote.makeEntry(title: "Recovery"))
        note.setUp(code)
        #expect(
            note.entry.sections.flatMap(\.fields).map(\.kind) == [.oneTimeCode],
            "a field made where there was none"
        )
    }
}
