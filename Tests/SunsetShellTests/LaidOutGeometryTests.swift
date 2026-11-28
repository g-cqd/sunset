import Foundation
import Observation
import SunsetTestSupport
import Testing

@testable import SunsetShellModel

/// Geometry a view reports while laid out is stored after the layout pass, and only when it changed: a write during the
/// pass re-entered AppKit's observation tracking of the layout (the owner, 2026-11-28: widening the sidebar crashed).
@MainActor @Suite("Geometry stored after the layout pass")
struct LaidOutGeometryTests {
    @Test func `the sidebar's width is stored after the pass, without notifying when it did not change`() async {
        let tabs = TabsModel()
        tabs.sidebarLaidOut(width: 240, duration: 0.25)
        #expect(tabs.slide.width == 0, "not during the pass")
        await RealWait.pass(.milliseconds(50))
        #expect(tabs.slide.width == 240 && tabs.slide.duration == 0.25)
        let notified = ChangeFlag()
        withObservationTracking {
            _ = tabs.slide
        } onChange: {
            notified.raise()
        }
        tabs.sidebarLaidOut(width: 240, duration: 0.25)
        await RealWait.pass(.milliseconds(50))
        #expect(!notified.isRaised, "the same width again changes nothing observed")
        tabs.sidebarLaidOut(width: 300, duration: 0.25)
        await RealWait.pass(.milliseconds(50))
        #expect(notified.isRaised && tabs.slide.width == 300)
    }
}
