import Testing

@testable import SunsetShell

/// The owner's note n52: "the command bar when window gets shrunk can overflow the window". Its width is its own while there
/// is room, else the room left with a margin on each side; its rows scroll in the height left under it.
@Suite("The command bar's size in a small window")
struct CommandBarSizeTests {
    @Test func `its own width when it fits, the room less a margin each side when not`() {
        #expect(CommandBarSize.width(room: 1200) == Design.Width.commandBar)
        #expect(CommandBarSize.width(room: 400) == 400 - 2 * Design.Space.l)
        #expect(CommandBarSize.width(room: 10) == 0)
    }

    @Test func `its height at most what is under its top, less a margin`() {
        #expect(CommandBarSize.height(room: 800, top: 56) == 800 - 56 - Design.Space.l)
        #expect(CommandBarSize.height(room: 50, top: 56) == 0)
    }
}
