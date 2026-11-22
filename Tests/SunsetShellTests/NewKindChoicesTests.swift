import SunsetPane
import SunsetShellModel
import Testing

/// The owner's note n71: the command bar makes a terminal or a document as it makes a page, by its rows.
@Suite("The command bar's new-tab kinds")
struct NewKindChoicesTests {
    private let all = Scopes()

    @Test func `under a new tab's empty field: a terminal and a document`() {
        #expect(NewKindChoices.kinds(typed: "", forNewPage: true, scopes: all) == [.terminal, .document])
        #expect(NewKindChoices.kinds(typed: "  ", forNewPage: true, scopes: all) == [.terminal, .document])
        #expect(NewKindChoices.kinds(typed: "", forNewPage: false, scopes: all).isEmpty, "Go to a tab: none unasked")
    }

    @Test func `found by what is typed, from two letters`() {
        #expect(NewKindChoices.kinds(typed: "term", forNewPage: false, scopes: all) == [.terminal])
        #expect(NewKindChoices.kinds(typed: "New Doc", forNewPage: false, scopes: all) == [.document])
        #expect(NewKindChoices.kinds(typed: "new", forNewPage: true, scopes: all) == [.terminal, .document])
        #expect(NewKindChoices.kinds(typed: "shell", forNewPage: false, scopes: all) == [.terminal])
        #expect(NewKindChoices.kinds(typed: "t", forNewPage: false, scopes: all).isEmpty)
        #expect(NewKindChoices.kinds(typed: "example.com", forNewPage: true, scopes: all).isEmpty)
    }

    /// n82: Shift-Cmd-T opens the command bar with the kinds of tab, a web page among them, those that are on.
    @Test func `a new tab's kinds: all that are on unasked; typed words narrow them`() {
        #expect(NewKindChoices.newTab(typed: "", scopes: all) == [.terminal, .page, .document])
        #expect(NewKindChoices.newTab(typed: "web", scopes: all) == [.page])
        #expect(NewKindChoices.newTab(typed: "doc", scopes: all) == [.document])
        var noTerminal = Scopes()
        noTerminal.terminal = false
        #expect(NewKindChoices.newTab(typed: "", scopes: noTerminal) == [.page, .document])
        // A page is not offered as a new kind in the search bar: it is what typing there makes.
        #expect(NewKindChoices.kinds(typed: "", forNewPage: true, scopes: all) == [.terminal, .document])
    }

    @Test func `a kind that is off is not offered`() {
        var noTerminal = Scopes()
        noTerminal.terminal = false
        #expect(NewKindChoices.kinds(typed: "", forNewPage: true, scopes: noTerminal) == [.document])
        var noDocuments = Scopes()
        noDocuments.documents = false
        #expect(NewKindChoices.kinds(typed: "new", forNewPage: true, scopes: noDocuments) == [.terminal])
    }
}
