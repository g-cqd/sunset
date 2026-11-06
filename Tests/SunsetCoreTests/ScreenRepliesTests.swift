import Testing

@testable import SunsetCore

/// Feeds `input` and returns what the terminal answered.
func answer(_ input: String, _ columns: Int = 10, _ rows: Int = 4) -> String {
    var terminal = Terminal(columns: columns, rows: rows)
    terminal.feed(input)
    return String(decoding: terminal.takeReplies(), as: UTF8.self)
}

func screen(_ input: String, _ columns: Int = 10, _ rows: Int = 4) -> Screen {
    var terminal = Terminal(columns: columns, rows: rows)
    terminal.feed(input)
    return terminal.screen
}

@Suite("Replies") struct ScreenRepliesTests {
    @Test func `primary and secondary device attributes`() {
        #expect(answer("\(esc)[c") == "\(esc)[?62;22c")
        #expect(answer("\(esc)[0c") == "\(esc)[?62;22c")
        #expect(answer("\(esc)[1c") == "")
        #expect(answer("\(esc)[>c") == "\(esc)[>1;10;0c")
        #expect(answer("\(esc)[>0c") == "\(esc)[>1;10;0c")
    }

    @Test func `device status and cursor position reports`() {
        #expect(answer("\(esc)[5n") == "\(esc)[0n")
        #expect(answer("\(esc)[6n") == "\(esc)[1;1R")
        #expect(answer("\(esc)[3;5H\(esc)[6n") == "\(esc)[3;5R")
        #expect(answer("\(esc)[?6n") == "\(esc)[?1;1;1R")
        #expect(answer("\(esc)[7n") == "")
        #expect(answer("0123456789\(esc)[6n") == "\(esc)[1;10R", "a pending wrap reports the last column")
    }

    @Test func `the cursor position is relative to the region in origin mode`() {
        #expect(answer("\(esc)[2;3r\(esc)[?6h\(esc)[1;1H\(esc)[6n") == "\(esc)[1;1R")
        #expect(answer("\(esc)[2;3r\(esc)[?6h\(esc)[2;1H\(esc)[6n") == "\(esc)[2;1R")
    }

    @Test func `window size in characters`() {
        #expect(answer("\(esc)[18t", 10, 4) == "\(esc)[8;4;10t")
    }

    @Test func `mode queries report set, reset and unknown modes`() {
        #expect(answer("\(esc)[?7$p") == "\(esc)[?7;1$y")
        #expect(answer("\(esc)[?7l\(esc)[?7$p") == "\(esc)[?7;2$y")
        #expect(answer("\(esc)[?9999$p") == "\(esc)[?9999;0$y")
        #expect(answer("\(esc)[4$p") == "\(esc)[4;2$y")
        #expect(answer("\(esc)[4h\(esc)[4$p") == "\(esc)[4;1$y")
        #expect(answer("\(esc)[?25$p") == "\(esc)[?25;1$y")
        #expect(answer("\(esc)[?1049$p") == "\(esc)[?1049;2$y")
        #expect(answer("\(esc)[?1049h\(esc)[?1049$p") == "\(esc)[?1049;1$y")
        #expect(answer("\(esc)[?3$p") == "\(esc)[?3;4$y", "DECCOLM is permanently reset: we never resize on request")
        #expect(answer("\(esc)[?2026h\(esc)[?2026$p") == "\(esc)[?2026;1$y")
        #expect(answer("\(esc)[?2004$p") == "\(esc)[?2004;2$y")
    }

    @Test func `cursor blinking is one state for mode 12 and DECSCUSR`() {
        #expect(answer("\(esc)[?12$p") == "\(esc)[?12;1$y")
        #expect(answer("\(esc)[?12l\(esc)[?12$p") == "\(esc)[?12;2$y")
        #expect(answer("\(esc)[2 q\(esc)[?12$p") == "\(esc)[?12;2$y")
        #expect(answer("\(esc)[2 q\(esc)[?12h\(esc)[?12$p") == "\(esc)[?12;1$y")
        #expect(answer("\(esc)[?12l\(esc)[5 q\(esc)[?12$p") == "\(esc)[?12;1$y")
    }

    @Test func `terminal name and version`() {
        #expect(answer("\(esc)[>0q") == "\(esc)P>|sunset(0.0.1)\(esc)\\")
    }

    @Test func `replies come in the order of the questions`() {
        #expect(answer("\(esc)[c\(esc)[5n\(esc)[6n") == "\(esc)[?62;22c\(esc)[0n\(esc)[1;1R")
    }

    @Test func `a query cut at every byte is answered the same`() {
        var terminal = Terminal(columns: 10, rows: 4)
        for byte in Array("\(esc)[3;5H\(esc)[6n\(esc)[?7$p".utf8) {
            [byte].withUnsafeBufferPointer { terminal.feed($0.span) }
        }
        #expect(String(decoding: terminal.takeReplies(), as: UTF8.self) == "\(esc)[3;5R\(esc)[?7;1$y")
    }

    @Test func `taking the replies empties the queue`() {
        var terminal = Terminal(columns: 10, rows: 4)
        terminal.feed("\(esc)[5n")
        #expect(terminal.takeReplies() == Array("\(esc)[0n".utf8))
        #expect(terminal.takeReplies() == [])
    }

    @Test func `a flood of queries cannot grow the queue without bound`() {
        var terminal = Terminal(columns: 10, rows: 4)
        let query = String(repeating: "\(esc)[c", count: 100_000)
        terminal.feed(query)
        let replies = terminal.takeReplies()
        #expect(replies.count <= 65536)
        #expect(replies.count > 0)
        #expect(terminal.screen.droppedReplies > 0)
    }
}
