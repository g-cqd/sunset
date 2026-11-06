import Testing

@testable import SunsetCore

@Suite("Kitty keyboard flags") struct KeyboardFlagTests {
    @Test func `query, push, pop`() {
        #expect(answer("\(esc)[?u") == "\(esc)[?0u")
        #expect(answer("\(esc)[>1u\(esc)[?u") == "\(esc)[?1u")
        #expect(answer("\(esc)[>1u\(esc)[>2u\(esc)[?u") == "\(esc)[?2u")
        #expect(answer("\(esc)[>1u\(esc)[>2u\(esc)[<u\(esc)[?u") == "\(esc)[?1u")
        #expect(answer("\(esc)[>1u\(esc)[>2u\(esc)[>4u\(esc)[<2u\(esc)[?u") == "\(esc)[?1u")
        #expect(answer("\(esc)[<5u\(esc)[?u") == "\(esc)[?0u", "popping an empty stack leaves the defaults")
    }

    @Test func `set with modes 1 (replace), 2 (add) and 3 (remove)`() {
        #expect(answer("\(esc)[=5u\(esc)[?u") == "\(esc)[?5u")
        #expect(answer("\(esc)[=5;1u\(esc)[?u") == "\(esc)[?5u")
        #expect(answer("\(esc)[=1u\(esc)[=4;2u\(esc)[?u") == "\(esc)[?5u")
        #expect(answer("\(esc)[=7u\(esc)[=2;3u\(esc)[?u") == "\(esc)[?5u")
    }

    @Test func `the main and alternate screens have separate stacks`() {
        #expect(answer("\(esc)[>1u\(esc)[?1049h\(esc)[?u") == "\(esc)[?0u")
        #expect(answer("\(esc)[>1u\(esc)[?1049h\(esc)[>4u\(esc)[?1049l\(esc)[?u") == "\(esc)[?1u")
        #expect(screen("\(esc)[>1u").keyboardFlags == 1)
    }

    @Test func `the stack is bounded`() {
        // Twenty pushes keep the newest sixteen: sixteen pops empty it, an unbounded stack would still hold four.
        let pushes = String(repeating: "\(esc)[>1u", count: 20)
        #expect(answer(pushes + "\(esc)[<16u\(esc)[?u") == "\(esc)[?0u")
        #expect(answer(String(repeating: "\(esc)[>1u", count: 100_000) + "\(esc)[<16u\(esc)[?u") == "\(esc)[?0u")
    }
}
