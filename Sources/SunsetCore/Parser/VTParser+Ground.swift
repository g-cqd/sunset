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
}
