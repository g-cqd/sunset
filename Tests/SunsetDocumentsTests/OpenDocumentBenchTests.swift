import AppKit
import Darwin
import Foundation
import MarkdownLookKit
import SunsetTestSupport
import Testing

@testable import SunsetDocuments

/// What a document costs to open and to type in, by its size (there is no size limit; these are the costs). Off unless
/// `SUNSET_BENCH=1`; run in release: `SUNSET_BENCH=1 swift test -c release --filter OpenDocumentBench`.
@MainActor
@Suite("A document's cost by its size", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_BENCH"] == "1"))
struct OpenDocumentBenchTests {
    static func percentiles(_ samples: [Double]) -> String {
        let sorted = samples.sorted()
        func at(_ share: Double) -> Double {
            sorted[min(Int(Double(sorted.count) * share), sorted.count - 1)]
        }
        return String(format: "p50 %.2f ms, p90 %.2f ms, max %.2f ms", at(0.5), at(0.9), sorted[sorted.count - 1])
    }

    static func milliseconds(_ body: () -> Void) -> Double {
        let start = Stopwatch()
        body()
        let took = start.elapsed
        return Double(took.components.seconds) * 1000 + Double(took.components.attoseconds) / 1e15
    }

    static func footprint() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            unsafe pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                unsafe task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int(info.phys_footprint) : 0
    }

    /// Markdown as a person writes it: headings, paragraphs, lists, a table, code.
    static func markdown(bytes: Int) -> String {
        let section = """
            ## Section %d: tides of the North Sea

            The harbour at low tide is *quiet*; the **boats** lean on the mud and the gulls walk between them, as
            [the almanac](https://example.org/almanac/%d) says of every week of the year.

            - a first point, with `code` in it
            - a second, longer one that goes on past the edge of a narrow window and wraps
              1. nested, numbered
              2. and again

            | Port | High | Low |
            | --- | --- | --- |
            | Dover | 11:02 | 17:40 |
            | Calais | 11:31 | 18:05 |

            ```swift
            let tide = Tide(port: "Dover", at: .now)
            print(tide.height)
            ```


            """
        var text = "# A long document\n\n"
        var index = 0
        while text.utf8.count < bytes {
            text += String(format: section, index, index)
            index += 1
        }
        return text
    }

    static func log(bytes: Int) -> String {
        var text = ""
        var index = 0
        while text.utf8.count < bytes {
            text +=
                "2026-11-14T12:00:\(index % 60) worker[\(index % 9)] request \(index) took \(index % 311) ms * ok _done_\n"
            index += 1
        }
        return text
    }

    private func measure(_ name: String, _ text: String) throws {
        let folder = NSTemporaryDirectory() + "bench-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: folder) }
        let path = folder + "/" + name
        try text.write(toFile: path, atomically: true, encoding: .utf8)
        let open = OpenDocuments(store: nil)
        let read = (0 ..< 5).map { _ in Self.milliseconds { _ = FileContent.read(path) } }
        let before = Self.footprint()
        var held: OpenDocument?
        let first = Self.milliseconds { held = open.open(.file(path)) }
        let memory = Self.footprint() - before
        let document = try #require(held)
        let end = document.source.storage.length
        let typed = (0 ..< 30)
            .map { index in
                Self.milliseconds {
                    document.source.storage.replaceCharacters(in: NSRange(location: end + index, length: 0), with: "x")
                }
            }
        let middle = (0 ..< 30)
            .map { index in
                Self.milliseconds {
                    document.source.storage.replaceCharacters(
                        in: NSRange(location: end / 2 + index, length: 0),
                        with: "y"
                    )
                }
            }
        // The same with the page shown (something reads it after each key), as a rendered pane beside the source does.
        let shown = (0 ..< 10)
            .map { index in
                Self.milliseconds {
                    document.source.storage.replaceCharacters(in: NSRange(location: end + index, length: 0), with: "z")
                    _ = document.source.document
                }
            }
        let save = (0 ..< 5).map { _ in Self.milliseconds { try? document.save() } }
        let megabytes = Double(text.utf8.count) / 1_048_576
        print(
            String(
                format: "BENCH %@ (%.2f MB, %d rows): open %.1f ms; held %.1f MB",
                name,
                megabytes,
                document.source.document.rows.count,
                first,
                Double(memory) / 1_048_576
            )
        )
        print("BENCH \(name) read the file only:", Self.percentiles(read))
        print("BENCH \(name) a character typed at the end:", Self.percentiles(typed))
        print("BENCH \(name) a character typed in the middle:", Self.percentiles(middle))
        print("BENCH \(name) a character typed, the page shown:", Self.percentiles(shown))
        print("BENCH \(name) save:", Self.percentiles(save))
        open.close(document)
    }

    /// Where a typed character's time goes: the kit's own steps, one by one.
    private func parts(_ name: String, _ text: String) {
        let storage = NSTextStorage(string: text)
        var session = LabSession(text: text)
        let end = storage.length
        let offset = (0 ..< 10).map { _ in Self.milliseconds { _ = session.utf8Offset(ofUTF16: end) } }
        var whole = 0
        let replace = (0 ..< 10)
            .map { _ in
                Self.milliseconds {
                    let edit = session.replace(session.utf8Count ..< session.utf8Count, with: "x")
                    whole += edit.parsedWhole ? 1 : 0
                }
            }
        let hash = (0 ..< 10).map { _ in Self.milliseconds { _ = storage.string.hashValue } }
        let page = (0 ..< 5).map { _ in Self.milliseconds { _ = session.nativeDocument(settings: ViewerSettings()) } }
        print("PARTS \(name) the offset of the edit:", Self.percentiles(offset))
        print("PARTS \(name) the parser's replace (\(whole) of 10 parsed whole):", Self.percentiles(replace))
        print("PARTS \(name) the text's hash:", Self.percentiles(hash))
        print("PARTS \(name) the page made again:", Self.percentiles(page))
    }

    @Test func whereTheTimeGoes() {
        parts("large.md", Self.markdown(bytes: 2_000_000))
        parts("small.log", Self.log(bytes: 200_000))
    }

    @Test func bench() throws {
        try measure("small.md", Self.markdown(bytes: 20_000))
        try measure("medium.md", Self.markdown(bytes: 200_000))
        try measure("large.md", Self.markdown(bytes: 2_000_000))
        try measure("huge.md", Self.markdown(bytes: 10_000_000))
        try measure("small.log", Self.log(bytes: 200_000))
        try measure("large.log", Self.log(bytes: 10_000_000))
    }
}
