import Foundation
import Testing

@testable import SunsetDocuments

/// What a merge costs by the size of the document: it is made on the main actor when a file changes on disk under
/// edits. Off unless `SUNSET_BENCH=1`; run in release: `SUNSET_BENCH=1 swift test -c release --filter
/// DocumentMergeBench`.
@MainActor
@Suite(
    "A merge's cost by the document's size",
    .enabled(if: ProcessInfo.processInfo.environment["SUNSET_BENCH"] == "1")
)
struct DocumentMergeBenchTests {
    @Test(arguments: [20_000, 200_000, 2_000_000, 10_000_000])
    func `an edit here near the top, a change there near the end`(bytes: Int) {
        let base = OpenDocumentBenchTests.markdown(bytes: bytes)
        let mine = base.replacing("Section 2:", with: "Section two, edited here:", maxReplacements: 1)
        let last = base.components(separatedBy: "## Section ").count - 2
        let theirs = base.replacing("Section \(last):", with: "Section \(last), changed on disk:", maxReplacements: 1)
        #expect(mine != base && theirs != base)
        var merge = DocumentMerge()
        let samples = (0 ..< 15)
            .map { _ in
                OpenDocumentBenchTests.milliseconds {
                    merge = DocumentMerge(base: base, mine: mine, theirs: theirs, kind: .markdown)
                }
            }
        #expect(merge.changes.count == 1 && merge.conflicts.isEmpty)
        let pieces = TextPieces.of(base, kind: .markdown).count
        print("merge \(bytes) bytes, \(pieces) blocks: \(OpenDocumentBenchTests.percentiles(samples))")
        let cut = (0 ..< 15)
            .map { _ in
                OpenDocumentBenchTests.milliseconds { _ = TextPieces.of(base, kind: .markdown) }
            }
        print("  of which cutting one text into blocks: \(OpenDocumentBenchTests.percentiles(cut))")
    }

    /// The worst a merge can be asked: every block changed on both sides, so that nothing of the middle matches.
    @Test(arguments: [2000, 4000])
    func `every block changed on both sides`(blocks: Int) {
        let base = (0 ..< blocks).map { "Paragraph \($0).\n\n" }
        let mine = (0 ..< blocks + 1).map { "Mine \($0).\n\n" }
        let theirs = (0 ..< blocks + 2).map { "Theirs \($0).\n\n" }
        let samples = (0 ..< 5)
            .map { _ in
                OpenDocumentBenchTests.milliseconds {
                    _ = DocumentMerge(
                        base: base.joined(),
                        mine: mine.joined(),
                        theirs: theirs.joined(),
                        kind: .markdown
                    )
                }
            }
        print("merge, \(blocks) blocks all changed on both sides: \(OpenDocumentBenchTests.percentiles(samples))")
    }
}
