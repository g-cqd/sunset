import Testing

@testable import SunsetHost

@Suite("Sidebar resize handle placement") struct SidebarHandleTests {
    @Test func `docked, the handle is centred in the gap between the end of the tabs and the terminal card`() {
        // Column 200 wide; tabs end 4 pt inside it (196); the card starts 6 pt after it (206): the middle is 201.
        #expect(SidebarHandle.center(docked: true, width: 200, margin: 6, tabSideInset: 4) == 201)
        // No inset and no margin: the gap is empty and the handle is on the column's edge.
        #expect(SidebarHandle.center(docked: true, width: 200, margin: 0, tabSideInset: 0) == 200)
        // The tabs reach further than the card begins: the middle of 190 and 206 is 198.
        #expect(SidebarHandle.center(docked: true, width: 200, margin: 6, tabSideInset: 10) == 198)
    }

    @Test func `floating, it is centred between the end of the tabs and the panel's edge`() {
        #expect(SidebarHandle.center(docked: false, width: 200, margin: 6, tabSideInset: 4) == 198)
    }

    @Test func `its hit box is as wide as asked, but floating never wider than the strip it has to be in`() {
        #expect(SidebarHandle.hitWidth(docked: true, wanted: 8, tabSideInset: 4) == 8)
        #expect(SidebarHandle.hitWidth(docked: false, wanted: 8, tabSideInset: 4) == 4)
        #expect(SidebarHandle.hitWidth(docked: false, wanted: 8, tabSideInset: 0) == 2, "at least 2 pt to grab")
        #expect(SidebarHandle.hitWidth(docked: true, wanted: -3, tabSideInset: 4) == 2)
    }
}
