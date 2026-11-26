package import SunsetCore
package import SunsetRuntime

/// Kitty image animations' clock (roadmap 0010 E): the core keeps none, so this ticks the screen at each frame's deadline
/// on the runtime's monotonic clock and says when a frame changed. It waits in one place, for a wake: output, a key or the
/// pane shown (`TerminalWakes`), or its own timer for the next deadline, so an animation started or sped up while it waits
/// is not held back. With nothing playing, or the terminal not shown, there is no timer.
package enum AnimationPlayback {
    @MainActor
    package static func run(
        runtime: Runtime,
        wakes: AsyncStream<Void>,
        wake: AsyncStream<Void>.Continuation,
        isVisible: () -> Bool,
        advance: (Int64) -> Screen.AnimationTick,
        changed: () -> Void
    ) async {
        var iterator = wakes.makeAsyncIterator()
        var timer: (deadline: Int64, task: Task<Void, Never>)?
        defer { timer?.task.cancel() }
        while !Task.isCancelled {
            var next: Int64?
            let now = Int64(runtime.uptime() / .milliseconds(1))
            if isVisible() {
                let tick = advance(now)
                if tick.changed { changed() }
                next = tick.next
            }
            // A timer stays while its deadline is still the next one and still ahead.
            if let current = timer, current.deadline != next || now >= current.deadline {
                current.task.cancel()
                timer = nil
            }
            if let next, timer == nil {
                let wait = Duration.milliseconds(max(next - now, 1))
                timer = (next, runtime.task { if await runtime.sleep(for: wait) { wake.yield() } })
            }
            if await iterator.next() == nil { return }
        }
    }
}
