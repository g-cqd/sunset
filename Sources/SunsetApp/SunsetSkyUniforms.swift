import CoreGraphics

/// `SkyUniforms` of `App/SunsetSky.metal`, field for field: three pairs, nine numbers, then a pair (72 bytes; the pair
/// starts at 64, on its 8-byte alignment, in both).
struct SunsetSkyUniforms {
    var frameOrigin: SIMD2<Float>
    var frameSize: SIMD2<Float>
    var sun: SIMD2<Float>
    var skyOpacity: Float
    var sunOpacity: Float
    var sunDefocus: Float
    var elevation: Float
    var horizon: Float
    var time: Float
    var headroom: Float
    var scale: Float
    var sunAspect: SIMD2<Float>

    init(_ sky: SunsetSkyFrame, time: Double, headroom: CGFloat, scale: CGFloat) {
        frameOrigin = SIMD2(Float(sky.frame.minX), Float(sky.frame.minY))
        frameSize = SIMD2(Float(sky.frame.width), Float(sky.frame.height))
        sun = SIMD2(Float(sky.sun.x), Float(sky.sun.y))
        skyOpacity = Float(sky.skyOpacity)
        sunOpacity = Float(sky.sunOpacity)
        sunDefocus = Float(sky.sunDefocus)
        elevation = Float(sky.elevation)
        horizon = Float(sky.horizon)
        self.time = Float(time)
        self.headroom = Float(headroom)
        self.scale = Float(scale)
        sunAspect = SIMD2(Float(sky.sunAspect.width), Float(sky.sunAspect.height))
    }
}
