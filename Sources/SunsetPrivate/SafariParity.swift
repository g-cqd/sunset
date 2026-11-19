public import Foundation
internal import InternedStrings

/// What Safari gives pages that WebKit keeps off in an app's views (task t98, the inventory against a driven Safari): each a
/// feature of WebKit's own, turned on. A page tells Sunset from Safari by any difference (ADR-0089), and sites that look
/// for these (a scheduler using `requestIdleCallback`) take a slower way without them.
public enum SafariParity {
    @MainActor
    public static func turnOn(on preferences: NSObject) {
        for key in [
            #Interned("RequestIdleCallbackEnabled"), #Interned("MediaSessionCoordinatorEnabled"),
            #Interned("MediaSessionPlaylistEnabled")
        ] {
            WebFeature.set(key, enabled: true, on: preferences)
        }
    }
}
