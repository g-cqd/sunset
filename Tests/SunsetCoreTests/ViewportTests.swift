import Testing

@testable import SunsetCore

@Suite("Viewport state") struct ViewportTests {
    @Test func `it starts on the live screen`() {
        let viewport = Viewport()
        #expect(viewport.isLive && viewport.scrolledBack == 0)
    }

    @Test func `scrolling goes back into the history and stops at both ends`() {
        var viewport = Viewport()
        viewport.follow(historyCount: 100)
        viewport.scroll(by: 30)
        #expect(viewport.scrolledBack == 30)
        viewport.scroll(by: 500)
        #expect(viewport.scrolledBack == 100)
        viewport.scroll(by: -40)
        #expect(viewport.scrolledBack == 60)
        viewport.scroll(by: -500)
        #expect(viewport.isLive)
    }

    @Test func `with no history there is nowhere to scroll`() {
        var viewport = Viewport()
        viewport.scroll(by: 5)
        #expect(viewport.isLive)
    }

    @Test func `new lines in the history keep the lines on show where they are`() {
        var viewport = Viewport()
        viewport.follow(historyCount: 10)
        viewport.scroll(by: 4)
        viewport.follow(historyCount: 13)
        #expect(viewport.scrolledBack == 7, "three lines were added below, the window moved up with its text")
    }

    @Test func `new lines leave the live screen live`() {
        var viewport = Viewport()
        viewport.follow(historyCount: 10)
        viewport.follow(historyCount: 20)
        #expect(viewport.isLive)
    }

    @Test func `a history that shrinks (cleared, or the other screen) brings the window back inside it`() {
        var viewport = Viewport()
        viewport.follow(historyCount: 50)
        viewport.scroll(by: 40)
        viewport.follow(historyCount: 0)
        #expect(viewport.isLive)
    }

    @Test func `scrolling by pages and back to the live screen`() {
        var viewport = Viewport()
        viewport.follow(historyCount: 100)
        viewport.scroll(by: 24)
        viewport.toLive()
        #expect(viewport.isLive)
    }

    @Test func `the first line on show counts from the oldest line of the history`() {
        var viewport = Viewport()
        viewport.follow(historyCount: 100)
        #expect(viewport.firstLine == 100)
        viewport.scroll(by: 30)
        #expect(viewport.firstLine == 70)
        viewport.follow(historyCount: 105)
        #expect(viewport.firstLine == 70, "the text on show did not move")
    }
}
