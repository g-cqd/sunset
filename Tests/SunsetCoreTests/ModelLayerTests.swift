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

extension ModelLayerTests {
    /// The web's policy (site rules, permissions, history, the browser a site is shown, search, downloads, what is typed in
    /// the address field) apart from the page and its views: no WebKit, no UI.
    @Test func `the web's model imports no WebKit nor UI, and holds the web's policy`() {
        let files = RepositoryFiles.swiftFiles(in: ["Sources/SunsetWebModel"])
        #expect(files.count > 40, "the scan must see the module: \(files.count) files")
        let banned = ["SwiftUI", "AppKit", "WebKit", "AemiSDR", "QuartzCore"]
        let found = files.filter { file in
            banned.contains { file.text.contains("import \($0)\n") }
        }
        #expect(found.isEmpty, "\(found.map(\.name))")
        let names = Set(files.map(\.name))
        for file in [
            "SiteRules.swift", "SitePermissions.swift", "HistoryStore.swift", "BrowserAgent.swift", "SearchEngine.swift"
        ] {
            #expect(names.contains(file), "\(file)")
        }
    }
}
