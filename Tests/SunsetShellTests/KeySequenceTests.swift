import Testing

@testable import SunsetShellModel

/// Two-key commands: "cmd+k cmd+t" in the file; the first key waits for the second, which runs the command.
@MainActor @Suite("Two-key commands")
struct KeySequenceTests {
    private let commandK = KeyChord("k")

    @Test func `two keys are read as the file writes them and as the menus do; the second may be plain`() {
        #expect(KeySequence(text: "cmd+k cmd+t") == KeySequence(commandK, then: KeyChord("t")))
        #expect(KeySequence(text: "cmd+k, t") == KeySequence(commandK, then: KeyChord(.character("t"), [])))
        #expect(KeySequence(text: "\u{2318}K \u{2318}T")?.symbols == "\u{2318}K \u{2318}T")
        #expect(KeySequence(text: "cmd+k t")?.text == "cmd+k t")
        #expect(KeySequence(text: "cmd+d")?.single == KeyChord("d"))
        #expect(KeySequence(text: "k t") == nil, "the first key has Command or Control")
        #expect(KeySequence(text: "cmd+k t u") == nil)
    }

    @Test func `the first key waits; the second runs its command; Escape or another key stops waiting`() {
        let keys = CommandKeys()
        keys.take(["splitRight": "cmd+k cmd+right", "splitDown": "cmd+k cmd+down"])
        let pending = PendingKeys()
        #expect(pending.press(KeyChord("d"), escape: false, keys: keys) == .pass, "Cmd-D runs nothing of two")
        #expect(pending.press(commandK, escape: false, keys: keys) == .wait)
        #expect(pending.first == commandK)
        #expect(pending.press(KeyChord(.down), escape: false, keys: keys) == .run(.splitDown))
        #expect(pending.first == nil)
        #expect(pending.press(commandK, escape: false, keys: keys) == .wait)
        #expect(pending.press(KeyChord(.character("x"), []), escape: false, keys: keys) == .cancel)
        #expect(pending.press(commandK, escape: false, keys: keys) == .wait)
        #expect(pending.press(KeyChord(.character("\u{1B}"), []), escape: true, keys: keys) == .cancel)
    }

    @Test func `a command whose one key starts two loses it; two keys given take the first from its command`() {
        let keys = CommandKeys()
        // Cmd-L opens the command bar; given as the first of two, the command bar has no key any more.
        let file = keys.giving(KeySequence(KeyChord("l"), then: KeyChord(.character("s"), [])), to: .settings, in: [:])
        #expect(file == ["settings": "cmd+l s", "commandBar": ""])
        keys.take(file)
        #expect(keys.sequence(for: .commandBar) == nil)
        #expect(keys.key(for: .settings) == nil, "a menu item shows one key, not two")
        #expect(keys.startsSequence(KeyChord("l")))
    }
}
