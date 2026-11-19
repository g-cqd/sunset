import Foundation
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A path typed in the command bar (R6, roadmap 0023 step M-f): when it names a file that is there, the bar offers to open
/// it. Only what is plainly a path: one from the root, or from the home folder.
@Suite("A path typed in the command bar")
struct TypedPathTests {
    private let root: String = {
        let made = NSTemporaryDirectory() + "typed-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: made + "/home/notes", withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: made + "/home/notes/a b.md", contents: Data("x".utf8))
        return made
    }()

    @Test func `a path from the root or the home folder to a file that is there`() {
        let home = root + "/home"
        #expect(TypedPath.file(root + "/home/notes/a b.md", home: home) == root + "/home/notes/a b.md")
        #expect(TypedPath.file("  ~/notes/a b.md ", home: home) == home + "/notes/a b.md")
        #expect(TypedPath.file(root + "/home/./notes/../notes/a b.md", home: home) == root + "/home/notes/a b.md")
        #expect(TypedPath.file("file://" + root + "/home/notes/a%20b.md", home: home) == root + "/home/notes/a b.md")
    }

    @Test func `not a folder, not a file that is not there, not a word`() {
        let home = root + "/home"
        #expect(TypedPath.file(root + "/home/notes", home: home) == nil)
        #expect(TypedPath.file("~/notes/missing.md", home: home) == nil)
        #expect(TypedPath.file("notes/a b.md", home: home) == nil, "from where is not known")
        #expect(TypedPath.file("a b.md", home: home) == nil)
        #expect(TypedPath.file("https://example.com/a.md", home: home) == nil)
        #expect(TypedPath.file("//example.com/a.md", home: home) == nil)
        #expect(TypedPath.file("", home: home) == nil && TypedPath.file("/", home: home) == nil)
        #expect(TypedPath.file("~", home: home) == nil)
    }
}
