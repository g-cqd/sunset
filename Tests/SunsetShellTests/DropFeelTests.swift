import Testing

@testable import SunsetShellModel

/// A tick when a drag snaps onto a new place that takes it; nothing otherwise.
@Suite("A drag's feel")
struct DropFeelTests {
    @Test func `a tick on each new place, none while it stays, none over nothing, none on leaving`() {
        var feel = DropFeel<String>()
        let ticks = [nil, "a", "a", "a", nil, nil, "b", "a", "a"].map { feel.over($0) }
        #expect(ticks == [false, true, false, false, false, false, true, true, false])
    }

    @Test func `back to the same place after nothing ticks again`() {
        var feel = DropFeel<Int>()
        #expect(feel.over(1) && !feel.over(nil) && feel.over(1))
    }
}
