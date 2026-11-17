import Testing

@testable import SunsetShell

/// The list is as tall as its rows, their spaces and its padding: none cut, none left over.
@Suite("A list of choices' height")
struct ChoiceListHeightTests {
    @Test func `rows, their spaces and the padding add up`() {
        #expect(ChoiceList.height(rows: 1, spacing: 4) == 34 + 8)
        #expect(ChoiceList.height(rows: 3, spacing: 4) == 3 * 34 + 2 * 4 + 8)
    }
}
