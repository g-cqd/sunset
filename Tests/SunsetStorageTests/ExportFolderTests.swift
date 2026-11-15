import Foundation
import Testing

@testable import SunsetStorage

/// Where Export All writes (R12 step ST-6): a dated folder of its own in the folder the person chose, and names that never
/// write over one another.
@Suite("The folder of an export") struct ExportFolderTests {
    let root = NSTemporaryDirectory() + "export-\(UUID().uuidString)"
    let day = Date(timeIntervalSince1970: 1_794_700_800)

    @Test func `an export is a new dated folder; a second one the same day has a number`() throws {
        defer { try? FileManager.default.removeItem(atPath: root) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let first = try ExportFolder.make(in: URL(fileURLWithPath: root), now: day, calendar: calendar)
        let second = try ExportFolder.make(in: URL(fileURLWithPath: root), now: day, calendar: calendar)
        #expect(
            first.lastPathComponent == "Sunset Export 2026-11-15"
                && second.lastPathComponent == "Sunset Export 2026-11-15 2"
        )
        var isFolder: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: second.path, isDirectory: &isFolder) && isFolder.boolValue)
    }

    @Test func `two files of one name: the second has a number before its extension`() {
        var names = ExportFolder.Names()
        #expect(names.next("Notes.md") == "Notes.md" && names.next("Notes.md") == "Notes 2.md")
        #expect(names.next("notes.md") == "notes 3.md", "the Mac's disks do not tell the case apart")
        #expect(names.next("Notes") == "Notes" && names.next("Notes") == "Notes 2")
        #expect(
            names.next(".md") == ".md" && names.next("a.b.txt") == "a.b.txt" && names.next("a.b.txt") == "a.b 2.txt"
        )
    }

    @Test func `a cell of a CSV file is quoted when it must be, and never starts a formula`() {
        #expect(CSV.cell("plain") == "plain")
        #expect(CSV.cell("a, b") == "\"a, b\"" && CSV.cell("say \"hi\"") == "\"say \"\"hi\"\"\"")
        #expect(CSV.cell("two\nlines") == "\"two\nlines\"")
        // A page's title is the page's to choose: a spreadsheet must not run it (CWE-1236).
        #expect(CSV.cell("=HYPERLINK(\"http://x\")") == "\"'=HYPERLINK(\"\"http://x\"\")\"")
        #expect(
            CSV.cell("+1") == "'+1" && CSV.cell("-1") == "'-1" && CSV.cell("@x") == "'@x" && CSV.cell("\tx") == "'\tx"
        )
        #expect(CSV.line(["a", "b,c", ""]) == "a,\"b,c\",\r\n")
    }
}

/// Export All, whole: the steps the app gives it, what is written and what is said.
extension ExportFolderTests {
    @Test func `each part is written in the export's folder, and what was exported is said in one sentence`() throws {
        defer { try? FileManager.default.removeItem(atPath: root) }
        let outcome = ExportAll.run(into: URL(fileURLWithPath: root), now: day) { folder in
            [
                ExportAll.Step(said: "2 documents", problem: "Not exported: Broken."),
                ExportAll.file(Data("a,b\r\n".utf8), named: "History.csv", in: folder, said: "the history (1 page)"),
                nil,
                ExportAll.file(Data("{}".utf8), named: "Session.json", in: folder, said: "the session")
            ]
        }
        let folder = try #require(outcome.folder)
        #expect(folder.deletingLastPathComponent().path == URL(fileURLWithPath: root).path)
        #expect(
            outcome.sentence
                == "Exported 2 documents, the history (1 page) and the session, as plain files. Not exported: Broken."
        )
        #expect(try String(contentsOf: folder.appending(path: "History.csv"), encoding: .utf8) == "a,b\r\n")
        let mode =
            try FileManager.default.attributesOfItem(atPath: folder.appending(path: "Session.json").path)[
                .posixPermissions
            ]
        #expect(mode as? Int == 0o644, "a file of the person's, not one of the store's")
    }

    @Test func `nothing to export is said; a folder that cannot be made is said, and nothing is written`() {
        defer { try? FileManager.default.removeItem(atPath: root) }
        let none = ExportAll.run(into: URL(fileURLWithPath: root), now: day) { _ in [nil] }
        #expect(none.sentence == "There was nothing to export." && none.folder != nil)
        var ran = false
        let refused = ExportAll.run(into: URL(fileURLWithPath: "/dev/null/nowhere"), now: day) { _ in
            ran = true
            return []
        }
        #expect(
            refused.folder == nil && !ran
                && refused.sentence == "The export's folder could not be made in /dev/null/nowhere."
        )
        let one = ExportAll.run(into: URL(fileURLWithPath: root), now: day) { _ in [ExportAll.Step(said: "1 document")]
        }
        #expect(one.sentence == "Exported 1 document, as plain files.")
    }
}
