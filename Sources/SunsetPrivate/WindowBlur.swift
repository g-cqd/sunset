internal import Darwin
internal import InternedStrings

/// The blur behind a window with a radius of your choosing (the public materials, `NSVisualEffectView` and the glass view, have a fixed one). The window
/// server has a call for it that macOS does not document: it is the one iTerm2, Ghostty and other terminals use for a blurred translucent background. It
/// takes the connection to the window server, a window number and a radius in points.
///
/// The names are not written in the binary as plain strings (they are decoded by InternedStrings when first needed) and are looked up with `dlsym` at run
/// time, so a macOS that has dropped or renamed them does not stop the app from starting: `isAvailable` is false and the caller falls back to a material.
public enum WindowBlur {
    /// `CGSConnectionID CGSMainConnectionID(void)`
    private typealias MainConnection = @convention(c) () -> UInt32
    /// `CGError CGSSetWindowBackgroundBlurRadius(CGSConnectionID, CGWindowID, int)`
    private typealias SetRadius = @convention(c) (UInt32, UInt32, Int32) -> Int32

    private struct Calls {
        let connection: MainConnection
        let setRadius: SetRadius
    }

    private static let calls: Calls? = {
        let connectionName = #Interned("CGSMainConnectionID")
        let radiusName = #Interned("CGSSetWindowBackgroundBlurRadius")
        guard let connection = unsafe dlsym(unsafe UnsafeMutableRawPointer(bitPattern: -2), connectionName),
            let radius = unsafe dlsym(unsafe UnsafeMutableRawPointer(bitPattern: -2), radiusName)
        else { return nil }
        return unsafe Calls(
            connection: unsafeBitCast(connection, to: MainConnection.self),
            setRadius: unsafeBitCast(radius, to: SetRadius.self)
        )
    }()

    /// Whether the window server's calls were found on this system.
    public static var isAvailable: Bool { calls != nil }

    /// The radius as the system takes it: whole points from 0 to 100.
    public static func clampedRadius(_ radius: Double) -> Int {
        guard !radius.isNaN else { return 0 }
        return Int(min(max(radius.rounded(), 0), 100))
    }

    /// Blurs what is behind the window with this number (`NSWindow.windowNumber`) by `radius` points; 0 turns the blur off. The window has to be transparent
    /// (not opaque, with a clear background) for the blur to show. Returns whether the call was made and succeeded.
    @discardableResult
    public static func setRadius(_ radius: Double, forWindowNumber number: Int) -> Bool {
        guard let calls, number >= 0, number <= Int(UInt32.max) else { return false }
        let status = calls.setRadius(calls.connection(), UInt32(number), Int32(clampedRadius(radius)))
        return status == 0
    }
}
