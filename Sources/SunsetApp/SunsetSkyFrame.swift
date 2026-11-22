import CoreGraphics
import SunsetShellModel

/// What the sky draws in one frame (`App/SunsetSky.metal`), in points from the view's top left: the sky placed in
/// `frame`, its sun, each with its own opacity.
struct SunsetSkyFrame {
    var frame: CGRect
    var sun: CGPoint
    var skyOpacity = 1.0
    var sunOpacity = 1.0
    var sunDefocus = 0.0
    var elevation: Double
    var horizon = Double(WelcomeOpening.sunHeight)
    var sunAspect = WelcomeOpening.windowAspect

    /// The whole view, sky and sun, as the welcome window draws it.
    static func window(_ size: CGSize) -> Self {
        let all = CGRect(origin: .zero, size: size)
        return Self(
            frame: all,
            sun: CGPoint(x: all.midX, y: all.height * WelcomeOpening.sunHeight),
            elevation: WelcomeOpening.elevation(at: .infinity)
        )
    }

    /// The opening's sun alone `time` seconds in, for the window at `frame`.
    static func opening(at time: Double, frame: CGRect) -> Self {
        let now = WelcomeOpening.at(time, frame: frame)
        return Self(
            frame: frame,
            sun: now.sun,
            skyOpacity: 0,
            sunOpacity: now.sunOpacity,
            sunDefocus: now.sunDefocus,
            elevation: WelcomeOpening.elevation(at: time),
            sunAspect: WelcomeOpening.sunAspect(roundness: now.sunRoundness)
        )
    }
}
