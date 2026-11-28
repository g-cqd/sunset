import Testing

@testable import SunsetShellModel

/// Keys as settings: the file gives a command a key, or takes its key away; a key given moves from the command that had it.
@MainActor @Suite("Commands' keys")
struct CommandKeysTests {
    @Test func `a key is read as the file writes it and as the menus do, and written back the same`() {
        #expect(KeyChord(text: "cmd+shift+d") == KeyChord("d", [.command, .shift]))
        #expect(KeyChord(text: "\u{21E7}\u{2318}D") == KeyChord("d", [.command, .shift]))
        #expect(KeyChord(text: "ctrl+opt+up") == KeyChord(.up, [.control, .option]))
        #expect(KeyChord(text: "cmd++") == KeyChord("+"))
        #expect(KeyChord(text: "cmd+shift+d")?.text == "shift+cmd+d")
        #expect(KeyChord(text: "shift+d") == nil)
        #expect(KeyChord(text: "cmd+hyper+d") == nil)
        #expect(KeyChord(text: "") == nil)
    }

    @Test func `the file's key replaces the table's; one taken away leaves none; what is not a command is said`() {
        let keys = CommandKeys()
        let issues = keys.take(["splitRight": "cmd+e", "splitDown": "", "nothing": "cmd+x", "newTab": "x"])
        #expect(keys.key(for: .splitRight) == KeyChord("e"))
        #expect(keys.key(for: .splitDown) == nil)
        #expect(keys.key(for: .newWindow) == KeyChord("n"))
        #expect(issues.map(\.path) == ["keys.newTab", "keys.nothing"])
        #expect(keys.isGiven(.splitRight) && !keys.isGiven(.newWindow))
    }

    @Test func `a key given to a command is taken from the one that had it; the table's key is left out of the file`() {
        let keys = CommandKeys()
        let given = keys.giving(KeySequence(KeyChord("n")), to: .splitRight, in: [:])
        #expect(given == ["splitRight": "cmd+n", "newWindow": ""])
        keys.take(given)
        #expect(keys.key(for: .newWindow) == nil)
        #expect(keys.giving(KeySequence(KeyChord("d")), to: .splitRight, in: ["splitRight": "cmd+n"]) == [:])
    }
}
