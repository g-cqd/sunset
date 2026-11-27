public import Foundation

/// WebKit's "Prefer Page Rendering Updates near 60fps" feature: on by default, it holds a page's animations and redraws near
/// 60 fps on a 120 Hz screen. Turned off, a page renders at the screen's rate (on by default).
public enum WebFrameRate {
    @MainActor
    public static func set(fullRate: Bool, on preferences: NSObject) {
        WebFeature.set("PreferPageRenderingUpdatesNear60FPSEnabled", enabled: !fullRate, on: preferences)
    }
}
