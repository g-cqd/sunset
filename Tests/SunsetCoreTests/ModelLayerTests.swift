import SunsetTestSupport
import Testing

/// Roadmap 0086 D (ADR-0087, the owner's note n55: "separation of concern"): the window's model is a module of its own that
/// knows no UI framework, and what every kind of tab content promises is in it.
@Suite("The window's model knows no UI")
struct ModelLayerTests {
    @Test func `no file of the model imports SwiftUI, AppKit or a drawing library`() {
        let files = RepositoryFiles.swiftFiles(in: ["Sources/SunsetShellModel"])
        #expect(files.count > 50, "the scan must see the module: \(files.count) files")
        let banned = ["SwiftUI", "AppKit", "AemiSDR", "QuartzCore"]
        let found = files.filter { file in
            banned.contains { file.text.contains("import \($0)\n") }
        }
        #expect(found.isEmpty, "\(found.map(\.name))")
    }

    @Test func `what a tab's content promises, its picture and the window's model are in the model`() {
        let names = Set(RepositoryFiles.swiftFiles(in: ["Sources/SunsetShellModel"]).map(\.name))
        for file in [
            "PaneContent.swift", "PaneGlyph.swift", "TabsModel.swift", "SpaceModel.swift", "FavoritesModel.swift"
        ] {
            #expect(names.contains(file), "\(file)")
        }
    }
}
