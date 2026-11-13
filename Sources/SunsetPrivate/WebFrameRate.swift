public import Foundation
internal import InternedStrings

/// WebKit's "Prefer Page Rendering Updates near 60fps" feature: on by default, it holds a page's animations and redraws near
/// 60 fps on a 120 Hz screen. Turned off, a page renders at the screen's rate (owner, 2026-11-13: on by default). Not public API:
/// found by its key among the preferences' features; nothing happens when it is not there.
public enum WebFrameRate {
    @MainActor
    public static func set(fullRate: Bool, on preferences: NSObject) {
        let list = #Interned("_features")
        let setter = NSSelectorFromString(#Interned("_setEnabled:forFeature:"))
        guard let type = type(of: preferences) as AnyObject as? NSObject,
            type.responds(to: NSSelectorFromString(list)),
            preferences.responds(to: setter),
            let features = type.value(forKey: list) as? [NSObject],
            let feature = features.first(where: {
                ($0.value(forKey: "key") as? String) == #Interned("PreferPageRenderingUpdatesNear60FPSEnabled")
            })
        else { return }
        typealias Setter = @convention(c) (NSObject, Selector, Bool, NSObject) -> Void
        let call = unsafeBitCast(preferences.method(for: setter), to: Setter.self)
        call(preferences, setter, !fullRate, feature)
    }
}
