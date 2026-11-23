import Testing

@testable import SunsetCore

/// Link addresses no cell uses are forgotten when the table fills (the outside audit's MEM-06: 65,535 links once seen kept
/// every address for the terminal's life, and new links then went unrecorded).
@Suite("Hyperlinks: the table compacts")
struct LinkTableCompactionTests {
    private func link(_ address: String, _ text: String) -> String {
        "\u{1B}]8;;\(address)\u{1B}\\\(text)\u{1B}]8;;\u{1B}\\"
    }

    @Test func `past capacity, the links still shown keep their address and a new one is recorded`() {
        var t = Terminal(columns: 20, rows: 3, scrollbackLimit: 0)
        t.feed(link("https://kept.example/", "kept") + "\r\n")
        // As many links as the table holds, each written over by the next: no cell keeps them.
        for index in 0 ..< LinkTable.capacity {
            t.feed("\u{1B}[3;1H" + link("https://gone.example/\(index)", "x"))
        }
        t.feed("\u{1B}[3;1H" + link("https://new.example/", "new"))
        #expect(t.screen.link(row: 0, column: 0) == "https://kept.example/")
        #expect(t.screen.link(row: 2, column: 0) == "https://new.example/", "recorded after the table compacted")
        #expect(t.screen.links.addresses.count < 16, "the unused ones forgotten: \(t.screen.links.addresses.count)")
    }
}
