import CoreGraphics
import SunsetShellModel

/// What the sky draws in one frame (`App/SunsetSky.metal`), in points from the view's top left: the sky placed in
/// `frame`, its sun, each with its own opacity, and the preset for the time of day (`SkyPreset`, n143).
struct SunsetSkyFrame {
    var frame: CGRect
    var sun: CGPoint
    var skyOpacity = 1.0
    var sunOpacity = 1.0
    var sunDefocus = 0.0
    var elevation: Double
    var horizon = Double(WelcomeOpening.sunHeight)
    var sunAspect = WelcomeOpening.windowAspect
    var preset = SkyPreset.sunset

    /// The whole view, sky and sun, as the welcome window draws it, in `preset`.
    static func window(_ size: CGSize, preset: SkyPreset = .sunset) -> Self {
        let all = CGRect(origin: .zero, size: size)
        return Self(
            frame: all,
            sun: CGPoint(x: all.midX, y: all.height * WelcomeOpening.sunHeight),
            elevation: WelcomeOpening.elevation(at: .infinity, for: preset),
            preset: preset
        )
    }

    /// The opening's sun alone `time` seconds in, for the window at `frame`, in `preset`.
    static func opening(at time: Double, frame: CGRect, preset: SkyPreset = .sunset) -> Self {
        let now = WelcomeOpening.at(time, frame: frame)
        return Self(
            frame: frame,
            sun: now.sun,
            skyOpacity: 0,
            sunOpacity: now.sunOpacity,
            sunDefocus: now.sunDefocus,
            elevation: WelcomeOpening.elevation(at: time, for: preset),
            sunAspect: WelcomeOpening.sunAspect(roundness: now.sunRoundness),
            preset: preset
        )
    }
}
