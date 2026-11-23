import TerminalKitCodecs
import Testing

@testable import SunsetCore

/// Sunset's copy of kitty's placeholder marks is the table ask draws with (roadmap 0010 E): TerminalKit's, read through its
/// public encoder, mark for mark; one mark out of place would put a piece of an image in the wrong cell.
@Suite("kitty placeholder marks") struct PlaceholderDiacriticsTests {
    @Test func `every mark is TerminalKit's, at the same number, and reads back`() throws {
        #expect(PlaceholderDiacritics.all.count == KittyPlaceholder.maximumIndex + 1)
        for number in 0 ... KittyPlaceholder.maximumIndex {
            let cell = try #require(KittyPlaceholder.cell(row: number, column: 0))
            let mark = Array(cell.unicodeScalars)[1].value
            #expect(PlaceholderDiacritics.all[number] == mark, "mark \(number)")
            #expect(PlaceholderDiacritics.number(of: mark) == number)
        }
        #expect(PlaceholderDiacritics.number(of: 0x0301) == nil, "an accent that is not a mark")
    }
}
