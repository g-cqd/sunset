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
