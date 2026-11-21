import Foundation
import Testing

@testable import SunsetAppCore

/// Sunset WebKit says when its engine is likely behind WebKit's security fixes (threat model D10), once for each engine.
@Suite("Sunset WebKit's engine freshness")
struct EngineFreshnessTests {
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func `its age in whole weeks; none for the native build`() {
        #expect(EngineFreshness.weeks(base: base, now: base.addingTimeInterval(6.9 * 86_400)) == 0)
        #expect(EngineFreshness.weeks(base: base, now: base.addingTimeInterval(56 * 86_400)) == 8)
        #expect(EngineFreshness.weeks(base: nil, now: base) == nil)
        #expect(
            EngineFreshness.weeks(base: base, now: base.addingTimeInterval(-86_400)) == 0,
            "a clock behind is not negative"
        )
    }

    @Test func `told from eight weeks, once for each engine`() {
        #expect(!EngineFreshness.tells(weeks: 7, base: "a", toldFor: nil))
        #expect(EngineFreshness.tells(weeks: 8, base: "a", toldFor: nil))
        #expect(!EngineFreshness.tells(weeks: 12, base: "a", toldFor: "a"))
        #expect(EngineFreshness.tells(weeks: 12, base: "b", toldFor: "a"), "a newer engine that ages in turn")
        #expect(!EngineFreshness.tells(weeks: nil, base: nil, toldFor: nil))
    }
}
