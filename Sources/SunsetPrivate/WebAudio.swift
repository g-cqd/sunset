public import Foundation
internal import InternedStrings

/// Whether a page plays sound, and muting it. Not public API: `WKWebView` says it plays sound by a key-value observable
/// property, and takes a muted state; both are looked up by name, and where WebKit no longer has them a page is never shown
/// as playing and Mute does nothing.
@MainActor
public enum WebAudio {
    /// Tells `changed` each time the page starts or stops playing sound, for as long as the returned object is kept.
    public static func watchPlaying(_ view: NSObject, _ changed: @escaping @MainActor (Bool) -> Void) -> NSObject? {
        guard view.responds(to: NSSelectorFromString(playingKey)) else { return nil }
        return KeyWatch(view, key: playingKey) { changed(isPlaying(view)) }
    }

    public static func isPlaying(_ view: NSObject) -> Bool {
        guard view.responds(to: NSSelectorFromString(playingKey)) else { return false }
        return (view.value(forKey: playingKey) as? Bool) ?? false
    }

    public static func isMuted(_ view: NSObject) -> Bool {
        let key = #Interned("_mediaMutedState")
        guard view.responds(to: NSSelectorFromString(key)) else { return false }
        return ((view.value(forKey: key) as? UInt) ?? 0) & audio != 0
    }

    /// Mutes the page's sound (not its camera or microphone).
    public static func setMuted(_ muted: Bool, on view: NSObject) {
        PrivateSetter.set(#Interned("_setPageMuted:"), to: muted ? audio : 0, on: view)
    }

    private static var playingKey: String {
        #Interned("_isPlayingAudio")
    }
    /// WebKit's muted state for sound (its other bits are the capture devices).
    private static let audio: UInt = 1
}
