/// A mouse event as the bytes the program asked for with its tracking mode and format (xterm's "Mouse Tracking" and its extensions 1005, 1006, 1015, 1016).
public enum MouseEncoder {
    /// The bytes to send, or nil when the program did not ask for this event (tracking off, a release in X10 mode, motion in a mode that does not report it, a position
    /// the format cannot carry).
    public static func encode(_ event: MouseEvent, tracking: MouseTracking, format: MouseFormat) -> [UInt8]? {
        guard reports(event, tracking: tracking), var code = buttonCode(event.button) else { return nil }
        let isRelease = event.action == .release
        if isRelease, wheel(event.button) { return nil }
        // Only the SGR formats say which button was released; the others send "released" (3).
        let keepsButton = format == .sgr || format == .sgrPixels
        if isRelease, !keepsButton { code = 3 }
        if tracking != .x10 { code += modifierBits(event.modifiers) }
        if event.action == .motion { code += 32 }
        let (x, y) = format == .sgrPixels ? (event.pixelX + 1, event.pixelY + 1) : (event.column + 1, event.row + 1)
        guard x >= 1, y >= 1 else { return nil }
        let prefix: [UInt8] = [0x1B, 0x5B]
        switch format {
            case .sgr, .sgrPixels:
                return prefix + Array("<\(code);\(x);\(y)\(isRelease ? "m" : "M")".utf8)
            case .urxvt:
                return prefix + Array("\(code + 32);\(x);\(y)M".utf8)
            case .x10:
                guard x <= 223, y <= 223 else { return nil }
                return prefix + [0x4D, UInt8(32 + code), UInt8(32 + x), UInt8(32 + y)]
            case .utf8:
                guard x <= 2015, y <= 2015 else { return nil }
                return prefix + [0x4D] + utf8(32 + code) + utf8(32 + x) + utf8(32 + y)
        }
    }

    private static func reports(_ event: MouseEvent, tracking: MouseTracking) -> Bool {
        switch tracking {
            case .none: false
            case .x10: event.action == .press && !wheel(event.button)
            case .normal: event.action != .motion
            case .button: event.action != .motion || event.button != .none
            case .any: true
        }
    }

    private static func wheel(_ button: MouseEvent.Button) -> Bool {
        switch button {
            case .wheelUp, .wheelDown, .wheelLeft, .wheelRight: true
            default: false
        }
    }

    /// The button's code; motion with no button held is 3 (the "released" code), as xterm reports it.
    private static func buttonCode(_ button: MouseEvent.Button) -> Int? {
        switch button {
            case .left: 0
            case .middle: 1
            case .right: 2
            case .none: 3
            case .wheelUp: 64
            case .wheelDown: 65
            case .wheelLeft: 66
            case .wheelRight: 67
        }
    }

    private static func modifierBits(_ modifiers: InputModifiers) -> Int {
        (modifiers.contains(.shift) ? 4 : 0) + (modifiers.contains(.option) ? 8 : 0)
            + (modifiers.contains(.control) ? 16 : 0)
    }

    private static func utf8(_ value: Int) -> [UInt8] {
        guard let scalar = Unicode.Scalar(UInt32(value)) else { return [] }
        return Array(String(Character(scalar)).utf8)
    }
}
