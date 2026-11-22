import Testing

@testable import SunsetPane

/// The scopes of the app that can be removed (2026-11-16 and 2026-11-17): the web, terminals, documents. Each is a kind
/// of pane; at least one is always on.
@Suite("The scopes that can be turned off")
struct ScopesTests {
    @Test func `each scope is a kind of pane; a kind that is none of the three is always allowed`() {
        var scopes = Scopes()
        #expect(scopes.allows(kind: "terminal") && scopes.allows(kind: "web") && scopes.allows(kind: "document"))
        scopes.web = false
        #expect(!scopes.allows(kind: "web") && scopes.allows(kind: "terminal") && scopes.allows(kind: "settings"))
        #expect(!scopes.allows(PaneDescriptor(kind: "web", state: ["url": "https://example.com"])))
        let nothing: PaneDescriptor? = nil
        #expect(scopes.allows(.terminal(directory: nil)) && scopes.allows(nothing), "no descriptor is a terminal")
        scopes.terminal = false
        #expect(!scopes.allows(nothing) && !scopes.allows(kind: "terminal") && scopes.allows(kind: "document"))
        #expect(Scopes.Scope.allCases.map(\.kind) == ["terminal", "web", "document", "passwords"])
        #expect(Scopes.Scope.terminal.kind == PaneDescriptor.terminalKind)
        #expect(Scopes.Scope.documents.kind == PaneDescriptor.documentKind)
        #expect(Scopes.Scope.allCases.map(\.name) == ["terminals", "the web", "documents", "passwords"])
        #expect(scopes[.documents] && !scopes[.web])
    }

    @Test func `at least one stays on: all three off is terminals on, and the last one on cannot be turned off`() {
        var scopes = Scopes(terminal: false, web: false, documents: false)
        #expect(scopes == Scopes(terminal: true, web: false, documents: false))
        scopes = Scopes(terminal: false, web: true, documents: false)
        #expect(!scopes.canTurnOff(.web) && scopes.canTurnOff(.terminal) == false, "it is off already")
        scopes[.web] = false
        #expect(scopes.web, "refused")
        scopes[.documents] = true
        #expect(scopes.canTurnOff(.web))
        scopes[.web] = false
        #expect(scopes == Scopes(terminal: false, web: false, documents: true))
    }

    @Test func `a kept entry is of the kinds it starts from; it is allowed when each is`() throws {
        var favorites = Favorites()
        var tabs = Workspace()
        let tab = tabs.add()
        let added = tabs.addPane(beside: tab.pane, edge: .right)
        let split = try #require(added)
        let item = try #require(tabs.items.first)
        let made = favorites.keep(item, contents: [split: .init(kind: "web", state: [:])])
        let id = try #require(made)
        let entry = try #require(favorites.entry(id))
        #expect(entry.kinds == ["terminal", "web"], "a pane with nothing said is a terminal")
        #expect(Scopes().allows(entry) && !Scopes(web: false).allows(entry) && !Scopes(terminal: false).allows(entry))
        #expect(Scopes(documents: false).allows(entry))
    }
}
