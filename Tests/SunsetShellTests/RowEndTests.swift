import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The sound, the microphone and the camera are a tab's buttons as the close button and the cup are, at its end, the cup's size,
/// one after another. Slot 0 is the close button's place while it hides, the next one while it shows.
@Suite("A row's end: close, cup, sound, microphone, camera")
struct RowEndTests {
    private func end(close: Bool, controls: Int, edited: Bool = false) -> RowEnd {
        RowEnd(
            size: 20,
            gap: 4,
            closeShown: close,
            controls: controls,
            edited: edited,
            markWidth: 6,
            leading: 10,
            trailing: 6
        )
    }

    @Test func `each control a button's width and a gap further in, after the close button while it shows`() {
        #expect(end(close: false, controls: 3).inset(of: 0, middle: 14) == 14)
        #expect(end(close: false, controls: 3).inset(of: 2, middle: 14) == 14 + 2 * 24)
        #expect(end(close: true, controls: 3).inset(of: 0, middle: 14) == 14 + 24)
        #expect(end(close: true, controls: 3).inset(of: 1, middle: 14) == 14 + 48)
    }

    @Test func `the title stops before every control and the edited mark`() {
        #expect(end(close: false, controls: 0).titleEnd == 0)
        #expect(end(close: true, controls: 0).titleEnd == 24)
        #expect(end(close: true, controls: 2).titleEnd == 24 + 48)
        #expect(end(close: false, controls: 2).titleEnd == 4 + 20 + 4 + 24)
        #expect(end(close: false, controls: 2, edited: true).titleEnd == 4 + 20 + 4 + 24 + 14)
        #expect(end(close: false, controls: 0, edited: true).titleEnd == 4 + 6 + 4)
    }

    @Test func `the edited mark just before the controls`() {
        // The mark's room is its width and a gap on each side: 14.
        #expect(end(close: true, controls: 1, edited: true).markInset(middle: 14) == 14 + 10 + 7 + 24)
        #expect(end(close: false, controls: 2, edited: true).markInset(middle: 14) == 14 + 10 + 7 + 24)
        #expect(end(close: false, controls: 0, edited: true).markInset(middle: 14) == 10 + 3)
    }
}
