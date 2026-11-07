/// Turns the wheel and trackpad deltas of scroll events into whole lines, keeping the part of a line not yet scrolled for the next event.
public struct ScrollAccumulator: Sendable, Equatable {
    private var remainder = 0.0

    public init() {}

    /// The whole lines to scroll for an event: positive goes back into the history, negative toward the live screen. `delta` is in points for a trackpad
    /// (`precise`: one line per `cellHeight` points, times `trackpad`) and in lines for a wheel (times `wheel`).
    public mutating func lines(delta: Double, precise: Bool, cellHeight: Double, trackpad: Double, wheel: Double) -> Int
    {
        let setting = precise ? trackpad : wheel
        let unit = precise ? cellHeight : 1
        guard delta.isFinite, unit > 0, setting.isFinite, setting > 0 else { return 0 }
        let lines = delta / unit * setting
        // Against the direction of what was left over: that is dropped, so the first events of a new direction count in full.
        if remainder != 0, (remainder < 0) != (lines < 0) { remainder = 0 }
        remainder += lines
        let whole = remainder.rounded(.towardZero)
        remainder -= whole
        return Int(max(min(whole, 10_000), -10_000))
    }
}
