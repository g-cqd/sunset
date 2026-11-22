import Testing

@testable import SunsetPane
@testable import SunsetShell
@testable import SunsetShellModel

/// "a setting to disable the previews (totally but also by kinds and even to disable it for folders or terminal or
/// documents)".
@Suite("Which rows show a preview")
struct PreviewKindsTests {
    @Test func `all by default; off, none; by kind, a tab of a kind turned off has none`() {
        var kinds = PreviewKinds()
        #expect(kinds.shows(kinds: ["web"]) && kinds.shows(kinds: ["terminal"]) && kinds.showsFolders)
        kinds.terminals = false
        #expect(!kinds.shows(kinds: ["terminal"]) && kinds.shows(kinds: ["web"]))
        #expect(kinds.shows(kinds: ["terminal", "web"]), "a split shows when one of its kinds does")
        kinds.documents = false
        #expect(!kinds.shows(kinds: [PaneDescriptor.documentKind]))
        kinds.folders = false
        #expect(!kinds.showsFolders)
        kinds = PreviewKinds()
        kinds.enabled = false
        #expect(!kinds.shows(kinds: ["web"]) && !kinds.showsFolders)
        #expect(PreviewKinds().shows(kinds: ["settings"]), "another kind follows the switch alone")
    }
}
