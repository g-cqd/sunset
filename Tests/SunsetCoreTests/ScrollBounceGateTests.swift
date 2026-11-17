import Foundation
import Testing

/// The owner, 2026-11-17: no scroll view bounces when it has nothing to scroll. Every SwiftUI scroll view of the views is
/// given `bouncesOnlyWhenScrolling()`: a file that makes `ScrollView` names it as many times.
@Suite("Scroll views bounce only when they scroll: the gate")
struct ScrollBounceGateTests {
    /// How many times `pattern` is in the code of `text` (comments left out).
    static func count(_ pattern: String, in text: String) -> Int {
        let code = text.split(separator: "\n")
            .map { line in
                String(line.split(separator: "//", maxSplits: 1, omittingEmptySubsequences: false).first ?? "")
            }
            .joined(separator: "\n")
        let expression = try? NSRegularExpression(pattern: pattern)
        return expression?.numberOfMatches(in: code, range: NSRange(code.startIndex..., in: code)) ?? 0
    }

    @Test func `every SwiftUI ScrollView in the views bounces only when it scrolls`() {
        let files = RepositoryFiles.swiftFiles(in: [
            "Sources/SunsetShell", "Sources/SunsetWeb", "Sources/SunsetApp", "Sources/SunsetMarkdown"
        ])
        let missing = files.compactMap { file -> String? in
            // SwiftUI's, not AppKit's `NSScrollView` nor a type named for it.
            let made = Self.count(#"(?<![A-Za-z])ScrollView( \{|\(\.)"#, in: file.text)
            let given = Self.count(#"\.bouncesOnlyWhenScrolling\(\)"#, in: file.text)
            return made > given ? "\(file.name): \(made) scroll views, \(given) given the rule" : nil
        }
        #expect(missing.isEmpty, "\(missing.sorted().joined(separator: "\n"))")
    }
}
