import Foundation

/// Inertia for a scroll wheel. A notch does not move the text at once: it gives it a speed that decays exponentially, so the text glides and stops. The
/// distance is the one the notch asked for (the speed is `lines / timeConstant`, and the integral of a decay with that constant is `lines`); only when it
/// is scrolled changes. Notches that arrive while it moves add their speed, so a quick spin goes further, and one in the other direction brakes it.
/// A trackpad needs none of this: the system sends its own momentum events.
public struct ScrollMomentum: Sendable, Equatable {
    /// Seconds for the speed to fall to 1/e of itself; 0 turns the inertia off.
    public var timeConstant: Double
    /// Lines per second, positive going back into the history.
    private var velocity = 0.0
    private var remainder = 0.0

    /// Below this speed (lines per second) it has stopped: the rest is under a tenth of a line.
    private static let restSpeed = 0.5

    public init(timeConstant: Double) {
        self.timeConstant = timeConstant.isFinite ? max(timeConstant, 0) : 0
    }

    public var isMoving: Bool { abs(velocity) > Self.restSpeed }

    /// A notch worth `lines` lines (negative: toward the live screen).
    public mutating func push(lines: Double) {
        guard lines.isFinite else { return }
        if timeConstant > 0 {
            velocity += lines / timeConstant
        } else {
            remainder += lines
        }
    }

    /// The whole lines to scroll for `seconds` of time passing.
    public mutating func advance(by seconds: Double) -> Int {
        if isMoving, seconds > 0, seconds.isFinite {
            let decay = exp(-seconds / timeConstant)
            remainder += velocity * timeConstant * (1 - decay)
            velocity *= decay
        }
        guard isMoving else { return settle() }
        return take()
    }

    /// At rest the distance still to go (what the speed left would cover) is added and the total rounded to the nearest line, so a notch always scrolls
    /// the lines it asked for and nothing is lost to the stop.
    private mutating func settle() -> Int {
        remainder += velocity * timeConstant
        velocity = 0
        let rounded = (remainder + (remainder < 0 ? -1e-6 : 1e-6)).rounded(.toNearestOrAwayFromZero)
        remainder = 0
        return Int(max(min(rounded, 10_000), -10_000))
    }

    /// The whole lines waiting, keeping the fraction.
    public mutating func take() -> Int {
        let whole = remainder.rounded(.towardZero)
        remainder -= whole
        return Int(max(min(whole, 10_000), -10_000))
    }

    /// A finger on the trackpad, a key press, a new screen: whatever moved is dropped.
    public mutating func stop() {
        velocity = 0
        remainder = 0
    }
}
