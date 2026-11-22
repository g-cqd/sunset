import Foundation
import Testing

@testable import SunsetWebModel

/// The Now Playing stack at the foot of the sidebar: a card for each page whose media played, the latest to start in
/// front, the tops of at most two more behind it; scrolling goes through them.
@Suite("The Now Playing stack")
struct MediaStackTests {
    private func page(_ name: String, playing: Bool = true) -> MediaPage {
        MediaPage(id: UUID(), title: name, host: "\(name).example", isPlaying: playing)
    }

    @Test func `a page that starts playing comes to the front; one that plays on keeps its place`() {
        var stack = MediaStack()
        let a = page("a")
        let b = page("b")
        stack.update(a)
        stack.update(b)
        #expect(stack.pages.map(\.title) == ["b", "a"])
        var louder = a
        louder.title = "a, its next song"
        stack.update(louder)
        #expect(stack.pages.map(\.title) == ["b", "a, its next song"], "still playing: it stays where it is")
        var paused = a
        paused.isPlaying = false
        stack.update(paused)
        #expect(stack.pages.map(\.isPlaying) == [true, false], "a paused page stays, to be played again")
        stack.update(a)
        #expect(stack.pages.map(\.id) == [a.id, b.id], "playing again: to the front")
    }

    @Test func `a page that never played is not a card`() {
        var stack = MediaStack()
        stack.update(page("quiet", playing: false))
        #expect(stack.pages.isEmpty)
    }

    @Test func `the front card and the tops of at most two more behind it`() {
        var stack = MediaStack()
        for name in ["a", "b", "c", "d"] { stack.update(page(name)) }
        #expect(stack.shown.map(\.title) == ["d", "c", "b"])
        stack.scroll(1)
        #expect(stack.shown.map(\.title) == ["c", "b", "a"])
        stack.scroll(5)
        #expect(stack.front?.title == "a" && stack.shown.map(\.title) == ["a"], "the last card has none behind it")
        stack.scroll(-9)
        #expect(stack.front?.title == "d")
    }

    @Test func `a card goes when its page does; the front stays on what was shown`() {
        var stack = MediaStack()
        let pages = ["a", "b", "c"].map { page($0) }
        for page in pages { stack.update(page) }
        stack.scroll(1)
        #expect(stack.front?.title == "b")
        stack.remove(pages[2].id)
        #expect(stack.front?.title == "b", "a card before the front went: the front is still b")
        stack.remove(pages[1].id)
        #expect(stack.front?.title == "a")
        stack.remove(pages[0].id)
        #expect(stack.front == nil && stack.shown.isEmpty)
    }

    @Test func `a page that starts playing is shown in front even after a scroll`() {
        var stack = MediaStack()
        let a = page("a")
        stack.update(a)
        stack.update(page("b"))
        stack.scroll(1)
        stack.update(page("c"))
        #expect(stack.front?.title == "c")
    }

    @Test func `a scroll moves one card once the fingers went far enough, however fast`() {
        var scroll = MediaStackScroll(threshold: 30)
        #expect(scroll.add(12) == 0 && scroll.add(12) == 0)
        #expect(scroll.add(12) == 1, "36 points: one card")
        #expect(scroll.add(200) == 1, "one card at a time")
        #expect(scroll.add(-31) == -1)
        scroll.end()
        #expect(scroll.add(20) == 0, "a new gesture starts from nothing")
    }
}
