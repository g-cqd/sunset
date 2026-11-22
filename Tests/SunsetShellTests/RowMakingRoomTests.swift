import Foundation
import SunsetPane
import Testing

@testable import SunsetShellModel

/// The rows on each side of where a dragged tab would go move apart; nothing else moves.
@Suite("Rows making room")
struct RowMakingRoomTests {
    private let rows = (0 ..< 4).map { _ in Workspace.ItemID() }

    private func offsets(owner: Int, _ action: TabDropAction) -> [CGFloat] {
        rows.map { RowMakingRoom.offset(of: $0, rows: rows, owner: rows[owner], action: action, room: 20) }
    }

    @Test func `before a row: the one above moves up, it moves down`() {
        #expect(offsets(owner: 2, .moveBefore) == [0, -10, 10, 0])
    }

    @Test func `after a row: it moves up, the one below moves down`() {
        #expect(offsets(owner: 1, .moveAfter) == [0, -10, 10, 0])
    }

    @Test func `at the ends only the row there moves; a split moves nothing`() {
        #expect(offsets(owner: 0, .moveBefore) == [10, 0, 0, 0])
        #expect(offsets(owner: 3, .moveAfter) == [0, 0, 0, -10])
        #expect(offsets(owner: 1, .split(.left)) == [0, 0, 0, 0])
    }
}
