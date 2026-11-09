extension VTParser {
    /// A control sequence that is whole in the input at `start` (`ESC [` there), parsed in one pass instead of a state machine step per byte: how many bytes
    /// it took, or nil to leave it to the state machine, with nothing changed. Only the plain forms are taken (a private marker first, digits, `;` and `:`,
    /// up to two intermediates, a final byte); anything else (a control inside, a cancel, too many parameters, any invalid form, the end of the input
    /// before the final byte) goes the slow way, which stays the reference (`VTParserCSIFastPathTests`). Colour and attribute sequences before every cell
    /// were 70 % of parsing such output, one byte at a time (comparison of 2026-11-09).
    @inline(never) mutating func wholeCSI<Sink: VTSink>(in input: Span<UInt8>, at start: Int, into sink: inout Sink)
        -> Int?
    {
        var index = start + 2
        let count = input.count
        var found = Parameters()
        var marker: UInt8 = 0
        var collected = Intermediates()
        var separator = Separator.none
        var nextIsSubParameter = false
        while index < count {
            let byte = input[index]
            switch byte {
                case 0x30 ... 0x39:
                    guard collected.count == 0 else { return nil }
                    if separator != .digits {
                        guard found.begin(subParameter: nextIsSubParameter) else { return nil }
                        nextIsSubParameter = false
                        separator = .digits
                    }
                    found.appendDigit(byte &- 0x30)
                case 0x3A, 0x3B:
                    guard collected.count == 0 else { return nil }
                    if separator != .digits, !found.begin(subParameter: nextIsSubParameter) { return nil }
                    nextIsSubParameter = byte == 0x3A
                    separator = .pending
                case 0x3C ... 0x3F:
                    // A private marker is valid only as the first byte.
                    guard index == start + 2 else { return nil }
                    marker = byte
                case 0x20 ... 0x2F:
                    guard collected.append(byte) else { return nil }
                case 0x40 ... 0x7E:
                    if separator == .pending, !found.begin(subParameter: nextIsSubParameter) { return nil }
                    sink.csi(found, marker: marker, intermediates: collected, final: byte)
                    state = .ground
                    return index + 1 - start
                default:
                    return nil
            }
            index += 1
        }
        return nil
    }
}
