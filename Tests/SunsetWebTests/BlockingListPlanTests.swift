import Foundation
import Testing

@testable import SunsetWebModel

/// What the app decided about blocking lists by itself, untested (`AppBlocking`), now the web's model's.
@Suite("Blocking lists: which, when, where")
struct BlockingListPlanTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func `only an https list is fetched`() {
        #expect(BlockingListPlan.address("https://easylist.to/easylist/easylist.txt") != nil)
        #expect(
            BlockingListPlan.address("http://easylist.to/easylist/easylist.txt") == nil,
            "a list in the clear could be changed on the way"
        )
        #expect(BlockingListPlan.address("file:///etc/hosts") == nil)
        #expect(BlockingListPlan.address("not an address") == nil)
    }

    @Test func `fetched again when not kept or older than four days`() {
        #expect(BlockingListPlan.isStale(keptAt: nil, now: now))
        #expect(!BlockingListPlan.isStale(keptAt: now.addingTimeInterval(-3 * 86_400), now: now))
        #expect(BlockingListPlan.isStale(keptAt: now.addingTimeInterval(-4 * 86_400 - 1), now: now))
    }

    @Test func `kept under a name made of its address's safe characters, at most 120 of them`() {
        #expect(BlockingListPlan.fileName(for: "https://a.example/list.txt") == "https___a_example_list_txt.txt")
        let long = "https://a.example/" + String(repeating: "x", count: 300)
        #expect(BlockingListPlan.fileName(for: long).count == 124)
        #expect(!BlockingListPlan.fileName(for: "https://a.example/../../etc").contains("/"))
    }
}
