/// What a string-introducing sequence is: its content follows as bytes until the string ends.
public enum StringKind: UInt8, Sendable {
    case osc
    case dcs
    /// Application program command (the kitty graphics protocol rides on it).
    case apc
    /// Privacy message.
    case pm
    /// Start of string.
    case sos
}
