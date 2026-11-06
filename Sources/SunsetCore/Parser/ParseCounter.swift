/// Parses bytes and counts what came out: a concrete (non-generic) front for the parser, so that benchmarks, fuzzers and diagnostics running in
/// another module exercise the specialised code (ADR-0020), not the generic entry.
public struct ParseCounter: Sendable {
    public private(set) var printable = 0
    public private(set) var controls = 0
    public private(set) var escapes = 0
    public private(set) var csis = 0
    public private(set) var strings = 0
    public private(set) var stringBytes = 0
    private var parser: VTParser

    public init(maxStringLength: Int = 1 << 20) {
        parser = VTParser(maxStringLength: maxStringLength)
    }

    public mutating func feed(_ bytes: Span<UInt8>) {
        var sink = Counting()
        parser.parse(bytes, into: &sink)
        printable += sink.printable
        controls += sink.controls
        escapes += sink.escapes
        csis += sink.csis
        strings += sink.strings
        stringBytes += sink.stringBytes
    }

    private struct Counting: VTSink {
        var printable = 0
        var controls = 0
        var escapes = 0
        var csis = 0
        var strings = 0
        var stringBytes = 0

        mutating func printASCII(_ run: Span<UInt8>) { printable += run.count }
        mutating func print(_ scalar: Unicode.Scalar) { printable += 1 }
        mutating func execute(_ control: UInt8) { controls += 1 }
        mutating func escape(_ intermediates: Intermediates, final: UInt8) { escapes += 1 }
        mutating func csi(_ parameters: Parameters, marker: UInt8, intermediates: Intermediates, final: UInt8) {
            csis += 1
        }
        mutating func stringStart(
            _ kind: StringKind,
            parameters: Parameters,
            marker: UInt8,
            intermediates: Intermediates,
            final: UInt8
        ) { strings += 1 }
        mutating func stringBytes(_ bytes: Span<UInt8>) { stringBytes += bytes.count }
        mutating func stringEnd(completed: Bool) {}
    }
}
