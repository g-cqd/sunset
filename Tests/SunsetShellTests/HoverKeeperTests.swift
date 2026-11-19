import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// n46: a hover's end while a menu is open waits for the menu to close.
@Suite("A hover held while a menu is open") struct HoverKeeperTests {
    @Test func `the pointer leaving while a menu tracks keeps the hover until the menu closes`() {
        var keeper = HoverKeeper()
        keeper.hover(true, menuOpen: false)
        keeper.hover(false, menuOpen: true)
        #expect(keeper.hovering, "its menu's button stays while the menu is up")
        keeper.menuClosed()
        #expect(!keeper.hovering)
    }

    @Test func `coming back before the menu closes keeps it; with no menu, a hover ends at once`() {
        var keeper = HoverKeeper()
        keeper.hover(true, menuOpen: false)
        keeper.hover(false, menuOpen: true)
        keeper.hover(true, menuOpen: true)
        keeper.menuClosed()
        #expect(keeper.hovering)
        keeper.hover(false, menuOpen: false)
        #expect(!keeper.hovering)
        keeper.menuClosed()
        #expect(!keeper.hovering)
    }
}
