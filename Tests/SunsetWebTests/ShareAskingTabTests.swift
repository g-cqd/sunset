import Foundation
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner, 2026-11-19: the asking tab itself is offered, in its Space, marked.
@Suite("Share: the asking tab")
struct ShareAskingTabTests {
    @Test func `the asking tab is listed by its title, marked as this tab; another tab by its title alone`() {
        let asking = ShareSource(
            id: UUID(),
            title: "Call",
            space: "Work",
            profile: nil,
            host: "meet.example",
            isAsking: true
        )
        let other = ShareSource(id: UUID(), title: "Notes", space: "Work", profile: nil, host: nil)
        #expect(asking.label == "Call (this tab)" && other.label == "Notes")
        #expect(
            TabShare.offered([asking, other], to: nil, otherProfiles: false).map(\.label) == [
                "Call (this tab)", "Notes"
            ]
        )
    }
}
