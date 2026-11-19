import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// 0035's "not done" (roadmap 0036 B): the command bar's rows in the sidebar's width cut their title in the middle
/// ("Searc…for "m""), the subtitle and the accessory taking its room. In a narrow row the title has the room first.
@Suite("What a choice row shows, by its width")
struct ChoiceRowPartsTests {
    @Test func `wide, everything; narrower, the subtitle goes first, then the accessory`() {
        let wide = ChoiceRowView.Parts(width: 560)
        #expect(wide.subtitle && wide.accessory)
        let sidebar = ChoiceRowView.Parts(width: 229)
        #expect(!sidebar.subtitle && !sidebar.accessory && sidebar.cutsAtEnd && !wide.cutsAtEnd)
        let between = ChoiceRowView.Parts(width: ChoiceRowView.Parts.subtitleWidth - 1)
        #expect(!between.subtitle && between.accessory)
    }
}
