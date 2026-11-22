import SwiftUI
import Testing

@testable import SunsetShell

/// One delegate for every row and tile of the sidebar. Its rules, apart from DropInfo (which only the system makes):
/// where the pointer is says what a drop would do; a target clears only its own mark.
@MainActor @Suite("A row's or a tile's drop")
struct PlacedDropDelegateTests {
    final class Mark {
        var value: (owner: Int, place: Bool)?
    }

    private func delegate(
        _ owner: Int,
        _ mark: Mark,
        open: Bool = true,
        dropped: @escaping @MainActor (Bool) -> Bool = { _ in true }
    )
        -> PlacedDropDelegate<Int, Bool>
    {
        PlacedDropDelegate(
            owner: owner,
            accepts: { open },
            place: { point in open ? point.y > 10 : nil },
            drop: dropped,
            active: Binding(get: { mark.value }, set: { mark.value = $0 })
        )
    }

    @Test func `the mark follows the pointer while a drop is possible, and is the target's own`() {
        let mark = Mark()
        let row = delegate(1, mark)
        row.over(CGPoint(x: 0, y: 2))
        #expect(mark.value?.owner == 1 && mark.value?.place == false)
        row.over(CGPoint(x: 0, y: 18))
        #expect(mark.value?.place == true)
        let other = delegate(2, mark, open: false)
        other.over(CGPoint(x: 0, y: 2))
        #expect(mark.value?.owner == 1, "a target that cannot take it leaves another's mark")
        other.left()
        #expect(mark.value?.owner == 1)
        row.left()
        #expect(mark.value == nil)
    }

    @Test func `a drop does what its place says, and clears the mark`() {
        let mark = Mark()
        var done: [Bool] = []
        let row = delegate(1, mark) { after in
            done.append(after)
            return true
        }
        row.over(CGPoint(x: 0, y: 18))
        #expect(row.dropped(at: CGPoint(x: 0, y: 18)) && done == [true] && mark.value == nil)
        #expect(!delegate(3, mark, open: false).dropped(at: .zero), "nothing to do here: not taken")
    }
}
