import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The owner, 2026-11-19: a tab loaded as another profile shows that profile's name always, also while it is not loaded (a
/// kept entry unloaded has no page: its saved state says which profile, `as`).
@MainActor @Suite("A tab's profile mark, loaded or not")
struct SavedProfileMarkTests {
    @Test func `a saved page's profile is named from its saved state; nothing without one`() {
        ProfileNames.mark = { $0 == "work-id" ? "Work" : nil }
        let saved = PaneDescriptor(kind: "web", state: ["url": "https://example.org/", "as": "work-id"])
        #expect(TabLabel.profileMark(model: nil, saved: saved) == "Work")
        #expect(TabLabel.profileMark(model: nil, saved: PaneDescriptor(kind: "web", state: [:])) == nil)
        #expect(TabLabel.profileMark(model: nil, saved: nil) == nil)
    }
}
