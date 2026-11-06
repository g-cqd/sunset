extension VTParser {
    mutating func dcs<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        switch byte {
            case 0x18, 0x1A: state = .ground
            case 0x1B: enterEscape()
            case 0x00 ... 0x1F, 0x7F: break
            case 0x20 ... 0x2F: collectIntermediate(byte, next: .dcsIntermediate)
            case 0x30 ... 0x3F: collectParameterByte(byte, intermediate: .dcsIntermediate, next: .dcsParameter)
            case 0x40 ... 0x7E:
                finishParameters()
                beginString(.dcs, header: byte, into: &sink)
            default:
                state = .ground
                return false
        }
        return true
    }

    mutating func beginString<Sink: VTSink>(_ kind: StringKind, header final: UInt8 = 0, into sink: inout Sink) {
        self.kind = kind
        stringLength = 0
        truncated = false
        heldC2 = false
        suppressed = kind == .dcs && invalid
        if !suppressed {
            if kind != .dcs { clear() }
            sink.stringStart(kind, parameters: parameters, marker: marker, intermediates: intermediates, final: final)
        }
        state = .string
    }

    mutating func stringByte<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        if heldC2 {
            heldC2 = false
            if byte == 0x9C {
                endString(completed: true, terminator: .st, into: &sink)
                return true
            }
            deliverByte(0xC2, to: &sink)
            return false
        }
        switch byte {
            case 0x18, 0x1A:
                endString(completed: false, terminator: .none, into: &sink)
            case 0x1B:
                state = .stringEscape
            case 0x07 where kind == .osc:
                endString(completed: true, terminator: .bel, into: &sink)
            case 0xC2:
                heldC2 = true
            default:
                deliverByte(byte, to: &sink)
        }
        return true
    }

    mutating func stringEscape<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        endString(completed: true, terminator: .st, into: &sink)
        if byte == 0x5C { return true }
        enterEscape()
        return false
    }

    mutating func endString<Sink: VTSink>(completed: Bool, terminator: StringTerminator, into sink: inout Sink) {
        if !suppressed { sink.stringEnd(completed: completed && !truncated, terminator: terminator) }
        suppressed = false
        heldC2 = false
        state = .ground
    }

    private mutating func deliverByte<Sink: VTSink>(_ byte: UInt8, to sink: inout Sink) {
        withSingle(byte) { deliver($0, to: &sink) }
    }

    /// Passes content on, up to the limit; the rest is dropped and marks the string truncated.
    mutating func deliver<Sink: VTSink>(_ bytes: Span<UInt8>, to sink: inout Sink) {
        guard !suppressed else { return }
        let room = maxStringLength - stringLength
        if bytes.count <= room {
            stringLength += bytes.count
            sink.stringBytes(bytes)
        } else {
            if room > 0 { sink.stringBytes(bytes.extracting(0 ..< room)) }
            stringLength = maxStringLength
            truncated = true
        }
    }
}
