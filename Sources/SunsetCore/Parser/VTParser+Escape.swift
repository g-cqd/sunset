extension VTParser {
    mutating func escape<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        switch byte {
            case 0x50: beginDCS()
            case 0x58: beginString(.sos, into: &sink)
            case 0x5B: beginCSI()
            case 0x5D: beginString(.osc, into: &sink)
            case 0x5E: beginString(.pm, into: &sink)
            case 0x5F: beginString(.apc, into: &sink)
            default: return escapeIntermediate(byte, into: &sink)
        }
        return true
    }

    /// Escape after its intermediates, and escape's own bytes but the string and CSI introducers: an intermediate collected
    /// (escape moves here with its first), a final dispatched, DEL ignored.
    mutating func escapeIntermediate<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        if byte < 0x20 { return anywhere(byte, into: &sink) }
        switch byte {
            case 0x20 ... 0x2F:
                if !intermediates.append(byte) { invalid = true }
                state = .escapeIntermediate
            case 0x30 ... 0x7E: dispatchEscape(byte, into: &sink)
            case 0x7F: break
            default:
                state = .ground
                return false
        }
        return true
    }

    private mutating func dispatchEscape<Sink: VTSink>(_ final: UInt8, into sink: inout Sink) {
        if !invalid { sink.escape(intermediates, final: final) }
        state = .ground
    }

    mutating func beginCSI() {
        clear()
        state = .csiEntry
    }

    mutating func beginDCS() {
        clear()
        state = .dcsEntry
    }

    /// The state diagram's arrows from anywhere (not ground's, not a string's): CAN and SUB to ground, ESC to escape, every other
    /// C0 executed where it is. `byte` is a C0 (below 0x20). Inlined: the parser's hottest branch, kept one function for the
    /// states that take it (roadmap 0086 E; measured before and after, diary 2026-11-20-12).
    @inline(__always)
    mutating func anywhere<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        switch byte {
            case 0x18, 0x1A: state = .ground
            case 0x1B: enterEscape()
            default: sink.execute(byte)
        }
        return true
    }
}
