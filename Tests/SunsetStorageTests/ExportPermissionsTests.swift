import Foundation
import Testing

@testable import SunsetStorage

/// Design 0007, threat A4: an export is plain text by nature, so it is the person's only: its folder 0700, its files
/// 0600 (they were 0644, readable by every account on the Mac), and the sentence after it says what it is.
@Suite("Export All: the person's only")
struct ExportPermissionsTests {
    @Test func `the folder is 0700, each file 0600, and the sentence says they are plain`() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory() + "export-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let outcome = ExportAll.run(into: root) { folder in
            [ExportAll.file(Data("a,b".utf8), named: "History.csv", in: folder, said: "the history")]
        }
        let folder = try #require(outcome.folder)
        #expect(try Self.mode(folder) == 0o700)
        #expect(try Self.mode(folder.appending(path: "History.csv")) == 0o600)
        #expect(outcome.sentence.contains("not encrypted"), "\(outcome.sentence)")
    }

    static func mode(_ url: URL) throws -> Int {
        try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int ?? -1
    }
}
