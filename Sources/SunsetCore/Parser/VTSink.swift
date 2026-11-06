/// Receives what the parser recognised. Every method has a defined meaning for every input; a sink never sees a partial sequence.
public protocol VTSink {
    /// A run of printable ASCII (0x20...0x7E), as a span of the input, so a sink can copy it in bulk.
    mutating func printASCII(_ run: Span<UInt8>)
    /// One decoded non-ASCII scalar; U+FFFD for an invalid UTF-8 sequence (one per maximal invalid subpart).
    mutating func print(_ scalar: Unicode.Scalar)
    /// A C0 control (0x00...0x1F except ESC, CAN and SUB, which the parser handles), or a C1 control that arrived as its UTF-8 scalar, reported as
    /// its value 0x80...0x9F so a sink can tell the two apart. DEL (0x7F) is ignored by the parser.
    mutating func execute(_ control: UInt8)
    /// `ESC intermediates final`.
    mutating func escape(_ intermediates: Intermediates, final: UInt8)
    /// `CSI marker parameters intermediates final`; `marker` is one of `<`, `=`, `>`, `?` or 0.
    mutating func csi(_ parameters: Parameters, marker: UInt8, intermediates: Intermediates, final: UInt8)
    /// A string begins. For `.dcs` the header (`DCS marker parameters intermediates final`) is given; for the others they are empty.
    mutating func stringStart(
        _ kind: StringKind,
        parameters: Parameters,
        marker: UInt8,
        intermediates: Intermediates,
        final: UInt8
    )
    /// Content bytes of the current string, in order, possibly in several pieces.
    mutating func stringBytes(_ bytes: Span<UInt8>)
    /// The string ended. `completed` is false when it was cancelled (CAN, SUB) or was longer than the limit and the rest dropped.
    mutating func stringEnd(completed: Bool, terminator: StringTerminator)
}
