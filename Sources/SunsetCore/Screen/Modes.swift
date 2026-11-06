public enum CursorShape: UInt8, Sendable {
    case block, underline, bar
}

public enum MouseTracking: UInt8, Sendable {
    case none
    /// Press only (mode 9).
    case x10
    /// Press and release (1000).
    case normal
    /// Plus motion while a button is held (1002).
    case button
    /// Plus all motion (1003).
    case any
}

public enum MouseFormat: UInt8, Sendable {
    case x10, utf8, sgr, urxvt, sgrPixels
}

/// The modes a program can switch, as the host needs to know them (to encode keys, mouse and paste) and as DECRQM reports them.
public struct Modes: Sendable, Equatable {
    // ANSI
    public var insert = false
    public var newLine = false
    // DEC private
    public var applicationCursorKeys = false
    public var reverseVideo = false
    public var origin = false
    public var autoWrap = true
    public var cursorVisible = true
    public var mouseTracking = MouseTracking.none
    public var mouseFormat = MouseFormat.x10
    public var focusEvents = false
    public var alternateScroll = false
    public var bracketedPaste = false
    public var synchronizedOutput = false
    /// DECKPAM / DECKPNM.
    public var applicationKeypad = false

    public init() {}
}
