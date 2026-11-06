extension VTParser {
    /// Control sequence introducer states (entry, parameters, intermediates) share one routine: the position is `state`, the rules are small.
    mutating func csi<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        switch byte {
            case 0x18, 0x1A: state = .ground
            case 0x1B: enterEscape()
            case 0x00 ... 0x1F: sink.execute(byte)
            case 0x20 ... 0x2F: collectIntermediate(byte, next: .csiIntermediate)
            case 0x30 ... 0x3F: collectParameterByte(byte, intermediate: .csiIntermediate, next: .csiParameter)
            case 0x40 ... 0x7E:
                if !invalid {
                    finishParameters()
                    if !invalid { sink.csi(parameters, marker: marker, intermediates: intermediates, final: byte) }
                }
                state = .ground
            case 0x7F: break
            default:
                state = .ground
                return false
        }
        return true
    }

    mutating func collectIntermediate(_ byte: UInt8, next: State) {
        if !intermediates.append(byte) { invalid = true }
        state = next
    }

    /// A byte 0x30...0x3F: a digit, `;`, `:` or one of `<=>?` (a private marker, valid only first).
    mutating func collectParameterByte(_ byte: UInt8, intermediate: State, next: State) {
        if state == intermediate {
            invalid = true
            return
        }
        switch byte {
            case 0x30 ... 0x39:
                if separator != .digits {
                    if !parameters.begin(subParameter: nextIsSubParameter) { invalid = true }
                    nextIsSubParameter = false
                    separator = .digits
                }
                if !invalid { parameters.appendDigit(byte - 0x30) }
            case 0x3B, 0x3A:
                if separator != .digits, !parameters.begin(subParameter: nextIsSubParameter) { invalid = true }
                nextIsSubParameter = byte == 0x3A
                separator = .pending
            default:
                // `<=>?`: a private marker, only as the very first byte after the introducer.
                if state == .csiEntry || state == .dcsEntry, marker == 0, separator == .none {
                    marker = byte
                } else {
                    invalid = true
                }
        }
        if state == .csiEntry || state == .dcsEntry { state = next }
    }

    /// A trailing `;` or `:` leaves one more empty parameter.
    mutating func finishParameters() {
        if separator == .pending, !parameters.begin(subParameter: nextIsSubParameter) { invalid = true }
    }
}
