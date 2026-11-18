import Foundation
import Testing

/// docs/design/folds-and-menus.md (the owner's note n45): every fold shows only the system's chevron before a text label, no
/// glyph button shows a menu indicator, and the sidebar's folders fold as every other fold does.
@Suite("Folds and menus follow one rule") struct FoldsAndMenusTests {
    private let sources = RepositoryFiles.swiftFiles(in: ["Sources"])

    @Test func `a fold's label is text only`() {
        var wrong: [String] = []
        for file in sources {
            let parts = file.text.components(separatedBy: "DisclosureGroup(").dropFirst()
            for part in parts {
                // Its label: what follows `} label: {` up to the fold's end, or none (a title given at once).
                guard let label = part.components(separatedBy: "} label: {").dropFirst().first else { continue }
                let body = label.components(separatedBy: "\n        }").first ?? label
                if body.contains("systemImage:") || body.contains("Image(") { wrong.append(file.name) }
            }
        }
        #expect(wrong.isEmpty, "\(wrong)")
    }

    @Test func `no glyph shows a menu indicator`() {
        let visible = sources.filter { $0.text.contains(".menuIndicator(.visible)") }.map(\.name)
        #expect(visible.isEmpty, "\(visible)")
    }

    @Test func `the sidebar's folders fold with the system's chevrons`() {
        let folder = sources.first { $0.name == "FolderRow.swift" }?.text ?? ""
        #expect(folder.contains("\"chevron.right\"") && folder.contains("\"chevron.down\""))
        #expect(!folder.contains("\"chevron.up\""))
    }
}
