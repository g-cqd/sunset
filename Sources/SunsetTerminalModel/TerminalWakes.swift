/// The streams that wake a terminal's timed tasks when they wait without a timer: the cursor's blink
/// (`TerminalModel+Blink`) and image animations (`TerminalModel+Animation`). Each keeps only the newest wake.
package struct TerminalWakes: Sendable {
    package let blink = AsyncStream<Void>.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
    package let animation = AsyncStream<Void>.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))

    package init() {}

    /// Something happened that may start, stop or show an animation, or end the cursor's rest.
    package func yieldAll() {
        blink.continuation.yield()
        animation.continuation.yield()
    }
}
