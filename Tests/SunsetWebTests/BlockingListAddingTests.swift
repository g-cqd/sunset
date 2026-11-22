import Foundation
import Testing

@testable import SunsetWebModel

/// A list is added in Settings by its address. Only https (a list in the clear could be changed on the way), once, and at
/// most `BlockingListPlan.most` lists: each is fetched by Sunset itself and compiled, so their number is bounded (white
/// paper §9).
@Suite("Blocking lists: added and removed by address")
struct BlockingListAddingTests {
    private let easy = ["https://easylist.to/easylist/easylist.txt"]

    @Test func `an https address is added once, trimmed; anything else is said and not added`() {
        #expect(
            BlockingListPlan.adding(" https://pgl.yoyo.org/adservers/serverlist.php \n", to: easy)
                == .added(easy + ["https://pgl.yoyo.org/adservers/serverlist.php"])
        )
        #expect(
            BlockingListPlan.adding("http://lists.example/a.txt", to: easy)
                == .refused("Only https addresses: a list in the clear could be changed on the way.")
        )
        #expect(
            BlockingListPlan.adding("lists.example/a.txt", to: easy)
                == .refused("Only https addresses: a list in the clear could be changed on the way.")
        )
        #expect(
            BlockingListPlan.adding("https://easylist.to/easylist/easylist.txt", to: easy)
                == .refused("That list is already fetched.")
        )
    }

    @Test func `at most so many lists`() {
        let full = (0 ..< BlockingListPlan.most).map { "https://lists.example/\($0).txt" }
        #expect(
            BlockingListPlan.adding("https://lists.example/more.txt", to: full)
                == .refused("At most \(BlockingListPlan.most) lists: remove one first.")
        )
    }

    @Test func `a list removed is no longer fetched; removing one not there changes nothing`() {
        let lists = easy + ["https://lists.example/a.txt"]
        #expect(BlockingListPlan.removing("https://lists.example/a.txt", from: lists) == easy)
        #expect(BlockingListPlan.removing("https://lists.example/none.txt", from: lists) == lists)
    }
}
