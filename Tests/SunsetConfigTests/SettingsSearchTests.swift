import Testing

@testable import SunsetConfig

@Suite("Settings search") struct SettingsSearchTests {
    private let entries = [
        SettingsEntry(id: "font.family", pane: "font", title: "Family", keywords: ["typeface", "name"]),
        SettingsEntry(id: "font.size", pane: "font", title: "Size", keywords: ["points", "zoom"]),
        SettingsEntry(id: "scroll.wheel", pane: "scrolling", title: "Wheel sensitivity", keywords: ["mouse", "notch"]),
        SettingsEntry(
            id: "scroll.trackpad",
            pane: "scrolling",
            title: "Trackpad sensitivity",
            keywords: ["touch", "finger"]
        ),
        SettingsEntry(id: "window.titlebar", pane: "window", title: "Title bar", keywords: ["decorations"]),
        SettingsEntry(id: "keyboard.meta", pane: "keyboard", title: "Option sends Escape", keywords: ["meta", "alt"])
    ]

    private func ids(_ query: String) -> [String] { SettingsSearch.matches(query, in: entries).map(\.id) }

    @Test func `an empty or blank query matches nothing`() {
        #expect(ids("").isEmpty)
        #expect(ids("   ").isEmpty)
    }

    @Test func `a title is found by any part of it, ignoring case`() {
        #expect(ids("SENSITIV") == ["scroll.wheel", "scroll.trackpad"])
        #expect(ids("bar") == ["window.titlebar"])
    }

    @Test func `keywords find a setting the title does not name`() {
        #expect(ids("mouse") == ["scroll.wheel"])
        #expect(ids("alt") == ["keyboard.meta"])
        #expect(ids("decorations") == ["window.titlebar"])
    }

    @Test func `every word of the query must match, in any order`() {
        #expect(ids("sensitivity track") == ["scroll.trackpad"])
        #expect(ids("sensitivity font").isEmpty)
    }

    @Test func `a title that starts with the query comes before one that only contains it`() {
        let more = entries + [SettingsEntry(id: "x", pane: "p", title: "Wide size", keywords: [])]
        #expect(SettingsSearch.matches("size", in: more).map(\.id) == ["font.size", "x"])
        #expect(
            SettingsSearch.matches("wi", in: more).map(\.id).first == "x",
            "a title starting with it beats keyword and later matches"
        )
    }

    @Test func `accents do not matter`() {
        let accented = [SettingsEntry(id: "a", pane: "p", title: "Éclairage", keywords: [])]
        #expect(SettingsSearch.matches("eclairage", in: accented).count == 1)
        #expect(SettingsSearch.matches("ÉCLAIR", in: accented).count == 1)
    }

    @Test func `the panes that hold matches, in the order of their first match`() {
        #expect(SettingsSearch.panes(of: SettingsSearch.matches("sensitivity", in: entries)) == ["scrolling"])
        // Best matches first: a title starting with "s", then titles containing it, then keywords only.
        #expect(
            SettingsSearch.panes(of: SettingsSearch.matches("s", in: entries)) == [
                "font", "scrolling", "keyboard", "window"
            ]
        )
    }
}
