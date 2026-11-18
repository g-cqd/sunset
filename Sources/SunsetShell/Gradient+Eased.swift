package import SwiftUI

extension Gradient {
    /// From `start` to `end` along an ease-in-out (smoothstep) curve instead of a straight line (owner, 2026-11-13, t231): a fade
    /// that starts and ends softly, with no visible edge where it begins.
    package static func eased(from start: Color, to end: Color) -> Gradient {
        let steps = Design.Fade.steps
        return Gradient(
            stops: (0 ... steps)
                .map { index in
                    let t = Double(index) / Double(steps)
                    let eased = t * t * (3 - 2 * t)
                    return Gradient.Stop(color: start.mix(with: end, by: eased), location: t)
                }
        )
    }

    /// An end's mask (`appearance.ends`, the owner's note n30): the eased fade from `start` to `end` while ends fade;
    /// else all shown (black), the end cut where the band stops.
    package static func end(from start: Color, to end: Color, fading: Bool) -> Gradient {
        fading ? eased(from: start, to: end) : Gradient(colors: [.black, .black])
    }
}
