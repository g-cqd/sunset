import Foundation

extension WelcomeOpeningScore {
    /// The arithmetic every voice of the score shares: an oscillator's phase, a smooth fade, an envelope.
    enum ScoreMath {
        /// A phase in `0 ..< 1` moved on by one sample of `hz`.
        static func advance(_ phase: Double, hz: Double, invSampleRate: Double) -> Double {
            let next = phase + hz * invSampleRate
            return next - floor(next)
        }

        /// 0 to 1 as `value` goes from 0 to 1, flat at both ends (a quintic smoothstep).
        static func smooth(_ value: Double) -> Double {
            let x = min(max(value, 0), 1)
            return x * x * x * (x * (6 * x - 15) + 10)
        }
    }

    /// A voice's loudness over time: in from `enterStart` over `enterLength` seconds, out from `leaveStart` over
    /// `leaveLength`.
    struct Envelope: Sendable {
        let enterStart: Double
        let enterLength: Double
        let leaveStart: Double
        let leaveLength: Double

        /// How far out it is at `time`: 1 before it leaves, 0 once it has.
        func leaving(at time: Double) -> Double {
            1.0 - ScoreMath.smooth((time - leaveStart) / leaveLength)
        }

        func level(at time: Double) -> Double {
            ScoreMath.smooth((time - enterStart) / enterLength) * leaving(at: time)
        }
    }
}
