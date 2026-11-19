import Foundation
import SunsetTestSupport
import Testing

/// The owner, 2026-11-19: "pay attention to all the font weight used by all the sf symbols to ensure they all align". A
/// control's symbol (the close button's size, `Design.Symbol.badge`) has one weight, `Design.Symbol.weight`; a tab's picture
/// (`Design.Symbol.row`) has the symbols' regular one; a tab's sound and devices are drawn as its close button is.
@Suite("SF Symbols: one weight per role")
struct SymbolWeightTests {
    private func sources() throws -> [(name: String, text: String)] {
        let root = RepositoryFiles.root.appending(path: "Sources")
        let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        return try (files?.allObjects as? [URL] ?? [])
            .filter { $0.pathExtension == "swift" }
            .map { ($0.lastPathComponent, try String(contentsOf: $0, encoding: .utf8)) }
    }

    @Test func `every control symbol at the badge size has the controls' weight`() throws {
        var wrong: [String] = []
        for (name, text) in try sources() {
            let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
            // The weight on the same line, or on the next two when the call is broken over lines.
            for (index, line) in lines.enumerated() where line.contains("size: Design.Symbol.badge") {
                let call = lines[index ..< min(lines.count, index + 3)].joined(separator: " ")
                if !call.contains("weight: Design.Symbol.weight") {
                    wrong.append("\(name): \(line.trimmingCharacters(in: .whitespaces))")
                }
            }
        }
        #expect(wrong.isEmpty, "\(wrong)")
    }

    @Test func `a tab's sound and devices are drawn at the controls' size and weight, in the bar too`() throws {
        let label = try sources().first { $0.name == "TabLabel.swift" }?.text ?? ""
        #expect(!label.contains("Image(systemName: sound.symbol).font(Design.Text.detail)"))
        #expect(label.components(separatedBy: "Design.Symbol.badge, weight: Design.Symbol.weight").count - 1 >= 2)
    }
}
