import Testing

@testable import SunsetCore

/// What the parser reported, as values, so tests compare whole sequences. Printable runs are expanded to one event per character, because where a
/// run is cut depends on how the input was split and the meaning does not.
enum Event: Equatable {
    case text(Unicode.Scalar)
    case execute(UInt8)
    case escape(UInt8, [UInt8])
    case csi(marker: UInt8, parameters: [Int], subMask: UInt32, intermediates: [UInt8], final: UInt8)
    case stringStart(StringKind, header: [Int], marker: UInt8, intermediates: [UInt8], final: UInt8)
    case stringBytes([UInt8])
    case stringEnd(completed: Bool)
}

/// Parses `input` in pieces of the given sizes (the last piece takes the rest) and returns the events.
func parse(_ input: [UInt8], pieces: [Int] = [], maxStringLength: Int = 1 << 20) -> [Event] {
    var parser = VTParser(maxStringLength: maxStringLength)
    var sink = Recorder()
    var offset = 0
    for size in pieces + [input.count] where offset < input.count {
        let end = min(input.count, offset + max(1, size))
        input[offset ..< end]
            .withUnsafeBufferPointer { buffer in
                parser.parse(buffer.span, into: &sink)
            }
        offset = end
    }
    return sink.events
}

func parse(_ text: String, pieces: [Int] = [], maxStringLength: Int = 1 << 20) -> [Event] {
    parse(Array(text.utf8), pieces: pieces, maxStringLength: maxStringLength)
}

func text(_ string: String) -> [Event] { string.unicodeScalars.map { .text($0) } }
