import SunsetCore
import SunsetHost
import SunsetRuntime

/// Kitty image animations (roadmap 0010 E): the core keeps no clock, so this task ticks the session at each frame's
/// deadline on the runtime's monotonic clock and draws when a frame changed. With nothing running, or the terminal not
/// shown, it waits for a wake (output, a key, the pane shown) instead of a timer.
extension TerminalModel {
    func animate(_ session: TerminalSession) async {
        var wakes = wakes.animation.stream.makeAsyncIterator()
        while !Task.isCancelled {
            guard isVisible else {
                if await wakes.next() == nil { return }
                continue
            }
            let now = Int64(runtime.uptime() / .milliseconds(1))
            let tick = session.advanceAnimations(nowMilliseconds: now)
            if tick.changed { requestFrame() }
            guard let next = tick.next else {
                if await wakes.next() == nil { return }
                continue
            }
            guard await runtime.sleep(for: .milliseconds(max(next - now, 1))) else { return }
        }
    }
}
