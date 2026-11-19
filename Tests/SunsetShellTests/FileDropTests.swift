import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A file dropped on the window (R6, roadmap 0023 step M-f, ADR-0040): on a terminal its path is typed for the program
/// there, as in every terminal; anywhere else it opens as a document. A dropped name is not the person's typing: one that
/// holds a control character is never sent to a shell.
@Suite("A dropped file")
struct FileDropTests {
    @Test func `on a terminal the path is typed, quoted only when the shell would read it otherwise`() {
        #expect(FileDrop.typed(["/tmp/notes.md"]) == "/tmp/notes.md ")
        #expect(FileDrop.typed(["/Users/gc/My Notes/a b.md"]) == "'/Users/gc/My Notes/a b.md' ")
        #expect(FileDrop.typed(["/tmp/it's.md"]) == #"'/tmp/it'\''s.md' "#)
        #expect(FileDrop.typed(["/tmp/a.md", "/tmp/b c.md"]) == "/tmp/a.md '/tmp/b c.md' ")
        #expect(FileDrop.typed(["/tmp/caf\u{E9}/\u{65E5}\u{672C}.md"]) == "'/tmp/caf\u{E9}/\u{65E5}\u{672C}.md' ")
        #expect(FileDrop.typed([]) == nil)
    }

    @Test(arguments: ["$HOME", "`id`", "a;b", "a&b", "a|b", "*", "a?", "(a)", "<a>", "!x", "#x", "~x", "\"a\"", "a\\b"])
    func `what a shell would expand, run or split is inside single quotes`(name: String) {
        let typed = FileDrop.typed(["/tmp/" + name])
        #expect(typed == "'/tmp/" + name + "' ")
    }

    @Test(arguments: ["\u{3}", "\n", "\r", "\u{1B}[201~", "\u{7F}", "\u{0}", "\t", "\u{9B}", "\u{2028}"])
    func `a name with a control character is not typed at all`(character: String) {
        #expect(FileDrop.typed(["/tmp/a" + character + "rm -rf ~"]) == nil)
        #expect(FileDrop.typed(["/tmp/fine.md", "/tmp/a" + character + "b"]) == nil, "nor the others dropped with it")
    }

    @Test func `on a terminal it is typed; elsewhere files open and folders do nothing`() {
        let folders: Set = ["/tmp/folder"]
        let isFolder: (String) -> Bool = { folders.contains($0) }
        #expect(
            FileDrop.outcome(of: ["/tmp/a.md", "/tmp/folder"], onTerminal: true, isFolder: isFolder)
                == .type("/tmp/a.md /tmp/folder ")
        )
        #expect(
            FileDrop.outcome(of: ["/tmp/a.md", "/tmp/folder", "/tmp/b.txt"], onTerminal: false, isFolder: isFolder)
                == .open(["/tmp/a.md", "/tmp/b.txt"])
        )
        #expect(FileDrop.outcome(of: ["/tmp/folder"], onTerminal: false, isFolder: isFolder) == .nothing)
        #expect(FileDrop.outcome(of: ["/tmp/a\nb"], onTerminal: true, isFolder: isFolder) == .nothing)
        #expect(FileDrop.outcome(of: [], onTerminal: true, isFolder: isFolder) == .nothing)
    }
}
