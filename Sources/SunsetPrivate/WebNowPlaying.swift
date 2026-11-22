internal import Darwin
public import Foundation
internal import InternedStrings

/// A page's media session, and the system's media commands (roadmap 0114, ADR-0115). Not public API: WebKit's session
/// calls are looked up by name (`responds(to:)`), MediaRemote's command with `dlsym`; where a macOS no longer has one, its
/// call does nothing and says so.
@MainActor
public enum WebNowPlaying {
    /// The system's media commands, as MediaRemote numbers them.
    public enum Command: Int32, Sendable {
        case nextTrack = 4
        case previousTrack = 5
    }

    private typealias Done = @convention(block) () -> Void
    private typealias Played = @convention(block) (Bool) -> Void
    /// `Boolean MRMediaRemoteSendCommand(MRMediaRemoteCommand, CFDictionaryRef)`
    private typealias Send = @convention(c) (Int32, CFDictionary?) -> Bool

    /// Pauses the page's media through its own session (its `pause` handler runs). False when WebKit has no such call.
    @discardableResult
    public static func pause(_ view: NSObject) async -> Bool {
        let selector = NSSelectorFromString(#Interned("_pauseNowPlayingMediaSession:"))
        guard view.responds(to: selector) else { return false }
        await withCheckedContinuation { (finished: CheckedContinuation<Void, Never>) in
            let done: Done = { finished.resume() }
            _ = view.perform(selector, with: done)
        }
        return true
    }

    /// Plays the page's media through its own session (its `play` handler runs). False when it did not, or cannot.
    @discardableResult
    public static func play(_ view: NSObject) async -> Bool {
        let selector = NSSelectorFromString(#Interned("_playPredominantOrNowPlayingMediaSession:"))
        guard view.responds(to: selector) else { return false }
        return await withCheckedContinuation { (finished: CheckedContinuation<Bool, Never>) in
            let played: Played = { finished.resume(returning: $0) }
            _ = view.perform(selector, with: played)
        }
    }

    /// Lets a page's video float in the system's picture in picture window, or not (`WKPreferences`).
    public static func allowPictureInPicture(_ allowed: Bool, in preferences: NSObject) {
        PrivateSetter.set(#Interned("_setAllowsPictureInPictureMediaPlayback:"), to: allowed, on: preferences)
    }

    /// Toggles the page's video in the system's picture in picture window, when WebKit says it can. False when it cannot.
    @discardableResult
    public static func togglePictureInPicture(_ view: NSObject) -> Bool {
        let can = #Interned("_canTogglePictureInPicture")
        let toggle = NSSelectorFromString(#Interned("_togglePictureInPicture"))
        guard view.responds(to: NSSelectorFromString(can)), view.responds(to: toggle),
            (view.value(forKey: can) as? Bool) == true
        else { return false }
        _ = view.perform(toggle)
        return true
    }

    /// Whether the system's media commands can be sent.
    public static var canSend: Bool {
        send != nil
    }

    /// Sends `command` to the app that is the system's now playing: the page that last started playing, if it is
    /// Sunset's. False when it could not be sent.
    @discardableResult
    public static func send(_ command: Command) -> Bool {
        guard let send else { return false }
        return send(command.rawValue, nil)
    }

    private static let send: Send? = {
        let path = #Interned("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote")
        guard let library = unsafe dlopen(path, RTLD_NOW),
            let symbol = unsafe dlsym(library, #Interned("MRMediaRemoteSendCommand"))
        else { return nil }
        return unsafe unsafeBitCast(symbol, to: Send.self)
    }()
}
