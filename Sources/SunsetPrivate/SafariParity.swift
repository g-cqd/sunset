public import Foundation
internal import InternedStrings

/// What Safari gives pages that WebKit keeps off in an app's views (the inventory against a driven Safari): each a
/// feature of WebKit's own, turned on. A page tells Sunset from Safari by any difference, and sites that look for these
/// (a scheduler using `requestIdleCallback`) take a slower way without them.
public enum SafariParity {
    @MainActor
    public static func turnOn(on preferences: NSObject) {
        for key in [
            "RequestIdleCallbackEnabled",
            "MediaSessionCoordinatorEnabled",
            "MediaSessionPlaylistEnabled",
            // `VideoPlaybackQuality.displayCompositedVideoFrames` (2026-11-20).
            "VideoQualityIncludesDisplayCompositingEnabled",
            "ContextMenuQRCodeDetectionEnabled"
        ] {
            WebFeature.set(key, enabled: true, on: preferences)
        }
        PrivateSetter.set(#Interned("_setServiceControlsEnabled:"), to: true, on: preferences)
        PrivateSetter.set(#Interned("_setFullScreenEnabled:"), to: true, on: preferences)
    }

    /// Enables WebKit's image controls / Live Text / QR detection on `configuration` when WebKit supports them, so
    /// image and page context menus include Copy Subject, Look Up (Visual Look Up), QR actions, and Services.
    @MainActor
    public static func configure(_ configuration: NSObject) {
        PrivateSetter.set(#Interned("_setImageControlsEnabled:"), to: true, on: configuration)
        PrivateSetter.set(#Interned("_setSystemTextExtractionEnabled:"), to: true, on: configuration)
        PrivateSetter.set(#Interned("_setContextMenuQRCodeDetectionEnabled:"), to: true, on: configuration)
    }
}
