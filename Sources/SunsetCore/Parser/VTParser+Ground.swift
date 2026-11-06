extension VTParser {
    mutating func ground<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        switch byte {
            case 0x18, 0x1A: break
            case 0x1B: enterEscape()
            case 0x00 ... 0x1F: sink.execute(byte)
            case 0x20 ... 0x7E: withSingle(byte) { sink.printASCII($0) }
            case 0x7F: break
            default: startSequence(byte, into: &sink)
        }
        return true
    }

    /// Calls `body` with `byte` as a one-element span (the fast path in `parse` handles runs; this is the byte after a restart). No allocation.
    func withSingle(_ byte: UInt8, _ body: (Span<UInt8>) -> Void) {
        withUnsafePointer(to: byte) { pointer in
            let buffer = unsafe UnsafeBufferPointer(start: pointer, count: 1)
            body(buffer.span)
        }
    }

    /// A byte at or above 0x80 in the ground state: the start of a UTF-8 sequence.
    private mutating func startSequence<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) {
        switch byte {
            case 0xC2 ... 0xDF: begin(byte & 0x1F, continuations: 1, range: 0x80 ... 0xBF)
            case 0xE0: begin(byte & 0x0F, continuations: 2, range: 0xA0 ... 0xBF)
            case 0xE1 ... 0xEC, 0xEE, 0xEF: begin(byte & 0x0F, continuations: 2, range: 0x80 ... 0xBF)
            case 0xED: begin(byte & 0x0F, continuations: 2, range: 0x80 ... 0x9F)
            case 0xF0: begin(byte & 0x07, continuations: 3, range: 0x90 ... 0xBF)
            case 0xF1 ... 0xF3: begin(byte & 0x07, continuations: 3, range: 0x80 ... 0xBF)
            case 0xF4: begin(byte & 0x07, continuations: 3, range: 0x80 ... 0x8F)
            default: sink.print(VTParser.replacement)
        }
    }

    private mutating func begin(_ bits: UInt8, continuations: UInt8, range: ClosedRange<UInt8>) {
        scalar = UInt32(bits)
        pendingContinuations = continuations
        lowest = range.lowerBound
        highest = range.upperBound
    }

    /// The next byte of a UTF-8 sequence. A byte outside the valid range ends the sequence with one U+FFFD and is read again.
    mutating func decodeContinuation<Sink: VTSink>(_ byte: UInt8, into sink: inout Sink) -> Bool {
        guard byte >= lowest, byte <= highest else {
            pendingContinuations = 0
            sink.print(VTParser.replacement)
            return false
        }
        scalar = scalar << 6 | UInt32(byte & 0x3F)
        pendingContinuations -= 1
        lowest = 0x80
        highest = 0xBF
        if pendingContinuations == 0 { finishScalar(&sink) }
        return true
    }

    private mutating func finishScalar<Sink: VTSink>(_ sink: inout Sink) {
        let value = scalar
        guard value >= 0x80, value <= 0x9F else {
            sink.print((Unicode.Scalar(value) ?? VTParser.replacement))
            return
        }
        switch value {
            case 0x90: beginDCS()
            case 0x98: beginString(.sos, into: &sink)
            case 0x9B: beginCSI()
            case 0x9C: break
            case 0x9D: beginString(.osc, into: &sink)
            case 0x9E: beginString(.pm, into: &sink)
            case 0x9F: beginString(.apc, into: &sink)
            default: sink.execute(UInt8(value))
        }
    }

    /// The scalar of a complete, well-formed UTF-8 sequence that starts at `index` (a lead byte of 0xC2 or more), and its length; nil when the sequence is
    /// cut short by the end of the input, is malformed, or encodes a C1 control (the state machine handles those, and what a partial sequence leaves behind).
    @inline(__always)
    func wholeScalar(in input: Span<UInt8>, at index: Int) -> (Unicode.Scalar, Int)? {
        let lead = input[index]
        let available = input.count - index
        switch lead {
            case 0xC2 ... 0xDF:
                guard available >= 2, let second = continuation(input[index + 1], 0x80 ... 0xBF) else { return nil }
                let value = UInt32(lead & 0x1F) << 6 | second
                return value >= 0xA0 ? Unicode.Scalar(value).map { ($0, 2) } : nil
            case 0xE0 ... 0xEF:
                guard available >= 3 else { return nil }
                let range: ClosedRange<UInt8> =
                    lead == 0xE0 ? 0xA0 ... 0xBF : lead == 0xED ? 0x80 ... 0x9F : 0x80 ... 0xBF
                guard let second = continuation(input[index + 1], range),
                    let third = continuation(input[index + 2], 0x80 ... 0xBF)
                else { return nil }
                return Unicode.Scalar(UInt32(lead & 0x0F) << 12 | second << 6 | third).map { ($0, 3) }
            case 0xF0 ... 0xF4:
                guard available >= 4 else { return nil }
                let range: ClosedRange<UInt8> =
                    lead == 0xF0 ? 0x90 ... 0xBF : lead == 0xF4 ? 0x80 ... 0x8F : 0x80 ... 0xBF
                guard let second = continuation(input[index + 1], range),
                    let third = continuation(input[index + 2], 0x80 ... 0xBF),
                    let fourth = continuation(input[index + 3], 0x80 ... 0xBF)
                else { return nil }
                return Unicode.Scalar(UInt32(lead & 0x07) << 18 | second << 12 | third << 6 | fourth).map { ($0, 4) }
            default:
                return nil
        }
    }

    @inline(__always)
    private func continuation(_ byte: UInt8, _ range: ClosedRange<UInt8>) -> UInt32? {
        range.contains(byte) ? UInt32(byte & 0x3F) : nil
    }
}
