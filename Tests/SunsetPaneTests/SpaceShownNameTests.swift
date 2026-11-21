import Testing

@testable import SunsetPane

/// What names a Space where it is shown (menus, the question before deleting it): the unnamed Space of before there
/// were Spaces is Home, never an empty label ("Move Its Tabs to …", seen on screen).
@Suite("A Space's shown name")
struct SpaceShownNameTests {
    @Test func `an unnamed Space is Home; a named one is its name`() {
        #expect(Space().shownName == "Home")
        #expect(Space(name: "   ").shownName == "Home")
        #expect(Space(name: "Work").shownName == "Work")
    }
}
