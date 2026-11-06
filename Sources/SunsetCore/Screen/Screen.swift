public struct Screen: Sendable {
    public let columns: Int
    public let rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }

    public func text(row: Int) -> String { "" }
    public var cursorRow: Int { 0 }
    public var cursorColumn: Int { 0 }
}

extension Screen: VTSink {
    public mutating func printASCII(_ run: Span<UInt8>) {}
    public mutating func print(_ scalar: Unicode.Scalar) {}
    public mutating func execute(_ control: UInt8) {}
    public mutating func escape(_ intermediates: Intermediates, final: UInt8) {}
    public mutating func csi(_ parameters: Parameters, marker: UInt8, intermediates: Intermediates, final: UInt8) {}
    public mutating func stringStart(
        _ kind: StringKind,
        parameters: Parameters,
        marker: UInt8,
        intermediates: Intermediates,
        final: UInt8
    ) {}
    public mutating func stringBytes(_ bytes: Span<UInt8>) {}
    public mutating func stringEnd(completed: Bool) {}
}
