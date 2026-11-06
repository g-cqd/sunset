/// The VT/ANSI state machine (the DEC ANSI-compatible parser of vt100.net, as xterm and every modern terminal extend it), over bytes and into a sink.
/// Allocation-free; the state survives between `parse` calls, so input may be split anywhere, even inside a UTF-8 sequence or an escape sequence.
///
/// Policy where terminals differ (each has a test):
/// - UTF-8 only. Invalid input gives U+FFFD per maximal invalid subpart (WHATWG), never an error.
/// - C1 controls count only when they arrive as UTF-8 scalars (U+0080...U+009F), and act like their ESC forms (xterm in UTF-8 mode). A non-ASCII
///   byte inside an escape or control sequence abandons the sequence and is read afresh.
/// - A control sequence with more than 32 parameters, more than 2 intermediates, or a parameter after an intermediate is ignored whole.
/// - Strings (OSC, DCS, APC, PM, SOS) end at ST (ESC \ or U+009C), at BEL for OSC, or at ESC starting another sequence; CAN and SUB cancel. Content
///   beyond `maxStringLength` is dropped and the string ends incomplete.
public struct VTParser: Sendable {
    /// Longest string content (OSC, DCS, APC, PM, SOS) passed on; the rest of a longer one is dropped and the string ends with `completed: false`.
    public let maxStringLength: Int

    enum State: UInt8, Sendable {
        case ground, escape, escapeIntermediate
        case csiEntry, csiParameter, csiIntermediate
        case dcsEntry, dcsParameter, dcsIntermediate
        /// Inside a string; `kind` says which.
        case string
        /// ESC seen inside a string: `\` ends it, anything else ends it and starts a new sequence.
        case stringEscape
    }

    enum Separator: UInt8, Sendable {
        /// No parameter started.
        case none
        /// Digits are being added to the last parameter.
        case digits
        /// A `;` or `:` was seen and the next parameter has not started.
        case pending
    }

    var state = State.ground
    var kind = StringKind.osc
    var parameters = Parameters()
    var intermediates = Intermediates()
    var marker: UInt8 = 0
    var separator = Separator.none
    var nextIsSubParameter = false
    /// The sequence being collected cannot be dispatched (overflow or misplaced byte); it is swallowed up to its final byte.
    var invalid = false
    /// The string being read is swallowed without a word (its header was invalid).
    var suppressed = false
    var stringLength = 0
    var truncated = false
    /// A 0xC2 was seen inside a string: with a following 0x9C it is the C1 string terminator, otherwise it is content.
    var heldC2 = false
    // UTF-8 decoder
    var pendingContinuations: UInt8 = 0
    var scalar: UInt32 = 0
    var lowest: UInt8 = 0x80
    var highest: UInt8 = 0xBF

    /// What an invalid UTF-8 sequence becomes.
    static let replacement: Unicode.Scalar = "\u{FFFD}"

    public init(maxStringLength: Int = 1 << 20) {
        self.maxStringLength = maxStringLength
    }

    public mutating func parse<Sink: VTSink>(_ input: Span<UInt8>, into sink: inout Sink) {
        var index = 0
        let count = input.count
        while index < count {
            let byte = input[index]
            if state == .ground, pendingContinuations == 0, byte >= 0x20, byte < 0x7F {
                var end = index + 1
                while end < count, input[end] >= 0x20, input[end] < 0x7F { end += 1 }
                sink.printASCII(input.extracting(index ..< end))
                index = end
            } else if state == .ground, pendingContinuations == 0, byte >= 0xC2,
                let (scalar, length) = wholeScalar(in: input, at: index)
            {
                // A whole, valid sequence of two to four bytes is in the input: no state machine step per byte.
                sink.print(scalar)
                index += length
            } else if state == .string, !heldC2, isStringData(byte) {
                var end = index + 1
                while end < count, isStringData(input[end]) { end += 1 }
                deliver(input.extracting(index ..< end), to: &sink)
                index = end
            } else if step(byte, into: &sink) {
                index += 1
            }
        }
    }

    /// Whether `byte` is plain content of the current string (not a terminator, a cancel or the start of a possible C1 terminator).
    @inline(__always) func isStringData(_ byte: UInt8) -> Bool {
        switch byte {
            case 0x18, 0x1A, 0x1B, 0xC2: false
            case 0x07: kind != .osc
            default: true
        }
    }

    /// Handles one byte; false means "this byte must be looked at again" (the state changed because of it).
    mutating func step<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        if pendingContinuations > 0 { return decodeContinuation(byte, into: &sink) }
        switch state {
            case .ground: return ground(byte, into: &sink)
            case .escape: return escape(byte, into: &sink)
            case .escapeIntermediate: return escapeIntermediate(byte, into: &sink)
            case .csiEntry, .csiParameter, .csiIntermediate: return csi(byte, into: &sink)
            case .dcsEntry, .dcsParameter, .dcsIntermediate: return dcs(byte, into: &sink)
            case .string: return stringByte(byte, into: &sink)
            case .stringEscape: return stringEscape(byte, into: &sink)
        }
    }

    mutating func clear() {
        parameters.reset()
        intermediates.reset()
        marker = 0
        separator = .none
        nextIsSubParameter = false
        invalid = false
    }

    mutating func enterEscape() {
        clear()
        state = .escape
    }
}
