extension VTParser {
    mutating func escape<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        switch byte {
            case 0x18, 0x1A: state = .ground
            case 0x1B: enterEscape()
            case 0x00 ... 0x1F: sink.execute(byte)
            case 0x20 ... 0x2F:
                if !intermediates.append(byte) { invalid = true }
                state = .escapeIntermediate
            case 0x50: beginDCS()
            case 0x58: beginString(.sos, into: &sink)
            case 0x5B: beginCSI()
            case 0x5D: beginString(.osc, into: &sink)
            case 0x5E: beginString(.pm, into: &sink)
            case 0x5F: beginString(.apc, into: &sink)
            case 0x30 ... 0x7E: dispatchEscape(byte, into: &sink)
            case 0x7F: break
            default:
                state = .ground
                return false
        }
        return true
    }

    mutating func escapeIntermediate<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        switch byte {
            case 0x18, 0x1A: state = .ground
            case 0x1B: enterEscape()
            case 0x00 ... 0x1F: sink.execute(byte)
            case 0x20 ... 0x2F: if !intermediates.append(byte) { invalid = true }
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
}
