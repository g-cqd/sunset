package import CoreGraphics

/// The welcome's opening at one moment: the sun and the sky in phases of their own, no purple shades, no drawn stand-in for the window,
/// the sun going down before the window phases in. So: the sun alone fades in, out of focus, slowly, over what is on screen, and sets
/// to where the window keeps it; then the real window fades in where it stands, its content coming into focus, and the opening's sun
/// fades as the window's own takes over. Coordinates are SwiftUI's (y down).
package struct WelcomeOpening: Equatable {
    /// The opening's sun: how much of it shows, and how far out of focus it is (1: a wide blur, 0: sharp).
    package var sunOpacity: Double
    package var sunDefocus: Double
    /// The real window: its opacity, and the blur of its content.
    package var windowOpacity: Double
    package var contentBlur: CGFloat
    package var sun: CGPoint
    /// How round the opening's sun is: 1 a circle; 0 the window's sun's shape (`windowAspect`).
    package var sunRoundness = 1.0

    package static let duration = 8.4
    package static let sunPhase = (start: 0.0, length: 2.8)
    /// The sun going down ("make it go down before starting the window phasing in"). It ends under the window's first
    /// moments: the window starts when 97% of the way is done, the rest too slow to see.
    package static let setPhase = (start: 1.4, length: 4.2)
    package static let windowPhase = (start: 5.0, length: 3.4)
    /// Where the sun appears, from the window's top, as a share of its height, before it sets to `sunHeight`.
    package static let riseHeight: CGFloat = 0.78
    /// The content's blur as the window starts to show.
    package static let startBlur: CGFloat = 28
    /// Where the window's sky keeps the sun, from its top, as a share of its height.
    package static let sunHeight: CGFloat = 0.9
    /// The window's sun: a little wider than tall, as a low sun looks through the air (distances scaled by this).
    package static let windowAspect = CGSize(width: 0.92, height: 1.08)

    /// The scale of distances from the sun's middle for `roundness` (1: a circle; 0: `windowAspect`).
    package static func sunAspect(roundness: Double) -> CGSize {
        let round = CGFloat(clamp(roundness))
        return CGSize(
            width: windowAspect.width + (1 - windowAspect.width) * round,
            height: windowAspect.height + (1 - windowAspect.height) * round
        )
    }

    /// The opening `time` seconds in, for a window at `frame`.
    package static func at(_ time: Double, frame: CGRect) -> Self {
        let rising = smooth(progress(time, sunPhase))
        let setting = smooth(progress(time, setPhase))
        let height = riseHeight + (sunHeight - riseHeight) * CGFloat(setting)
        let showing = smooth(progress(time, windowPhase))
        return Self(
            sunOpacity: rising * (1 - showing),
            sunDefocus: 1 - (0.55 * rising + 0.45 * showing),
            windowOpacity: showing,
            contentBlur: startBlur * (1 - showing),
            sun: CGPoint(x: frame.midX, y: frame.minY + frame.height * height),
            // Round while it appears; it takes the window's shape as it sets.
            sunRoundness: 1 - setting
        )
    }

    /// How far through `phase` `time` is, 0 to 1.
    private static func progress(_ time: Double, _ phase: (start: Double, length: Double)) -> Double {
        clamp((time - phase.start) / phase.length)
    }

    /// 0 to 1, eased in and out with no jolt at either end (smootherstep: speed and acceleration both start and end at
    /// zero).
    private static func smooth(_ value: Double) -> Double {
        let x = clamp(value)
        return x * x * x * (x * (6 * x - 15) + 10)
    }

    /// The sun's elevation in degrees `time` seconds in: rising from under the haze to where the window keeps it.
    package static func elevation(at time: Double) -> Double {
        -4 + 3.4 * (1 - pow(1 - clamp(time / duration), 3))
    }

    static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
