// Non-generic entry points over the generic model. Generic code is not specialised across a module boundary (without @inlinable on all of it): the first
// version of the benchmarks called Model<C8> from another module and cost 7x the instructions (scrolling 108 M -> 753 M). These concrete classes call the
// model with concrete types, so it is specialised here (a generic class's methods reached through its vtable are not: ScreenImpl<C> measured 753 M too), and a
// consumer pays one virtual call per chunk.
package class Screen {
    package func feed(_ chunk: UnsafeBufferPointer<UInt8>) { fatalError() }
    package func run(_ data: [UInt8]) { fatalError() }
    /// Copies the visible rows (logical order) as raw 64-bit words; only meaningful for the 8-byte cell.
    package func snapshot(into dst: UnsafeMutablePointer<UInt64>) { fatalError() }
    package var cursorRow: Int { fatalError() }
    package var coldRows: Int { fatalError() }
    package var coldBytes: Int { fatalError() }
    package var coldData: [UInt8] { fatalError() }
    package func setEvictSink(_ f: @escaping (UnsafeRawBufferPointer) -> Void) { fatalError() }
}
@inline(__always) func snapshotWords(_ m: Model<C8>, into dst: UnsafeMutablePointer<UInt64>) {
    for y in 0..<m.rows { (dst + y * m.cols).update(from: UnsafeRawPointer(m.rowPtr(y)).assumingMemoryBound(to: UInt64.self), count: m.cols) }
}
final class Screen8: Screen {
    let m: Model<C8>
    init(sb: Int, cold: Bool) { m = Model<C8>(cols: 120, rows: 40, sbCap: sb, cold: cold) }
    override func feed(_ chunk: UnsafeBufferPointer<UInt8>) { m.feed(chunk) }
    override func run(_ data: [UInt8]) { runChunked(m, data) }
    override func snapshot(into dst: UnsafeMutablePointer<UInt64>) { snapshotWords(m, into: dst) }
    override var cursorRow: Int { m.cy }
    override var coldRows: Int { m.coldRows }
    override var coldBytes: Int { m.cold.count }
    override var coldData: [UInt8] { m.cold }
    override func setEvictSink(_ f: @escaping (UnsafeRawBufferPointer) -> Void) { m.evictHook = f }
}
final class Screen16: Screen {
    let m: Model<C16>
    init(sb: Int, cold: Bool) { m = Model<C16>(cols: 120, rows: 40, sbCap: sb, cold: cold) }
    override func feed(_ chunk: UnsafeBufferPointer<UInt8>) { m.feed(chunk) }
    override func run(_ data: [UInt8]) { runChunked(m, data) }
    override func snapshot(into dst: UnsafeMutablePointer<UInt64>) {  }
    override var cursorRow: Int { m.cy }
    override var coldRows: Int { m.coldRows }
    override var coldBytes: Int { m.cold.count }
    override var coldData: [UInt8] { m.cold }
    override func setEvictSink(_ f: @escaping (UnsafeRawBufferPointer) -> Void) { m.evictHook = f }
}
final class Screen32: Screen {
    let m: Model<C32>
    init(sb: Int, cold: Bool) { m = Model<C32>(cols: 120, rows: 40, sbCap: sb, cold: cold) }
    override func feed(_ chunk: UnsafeBufferPointer<UInt8>) { m.feed(chunk) }
    override func run(_ data: [UInt8]) { runChunked(m, data) }
    override func snapshot(into dst: UnsafeMutablePointer<UInt64>) {  }
    override var cursorRow: Int { m.cy }
    override var coldRows: Int { m.coldRows }
    override var coldBytes: Int { m.cold.count }
    override var coldData: [UInt8] { m.cold }
    override func setEvictSink(_ f: @escaping (UnsafeRawBufferPointer) -> Void) { m.evictHook = f }
}
package enum CellKind: String, CaseIterable { case c8 = "C8", c16 = "C16", c32 = "C32" }
package func makeScreen(_ kind: CellKind, sb: Int = 0, cold: Bool = false) -> Screen {
    switch kind {
    case .c8: return Screen8(sb: sb, cold: cold)
    case .c16: return Screen16(sb: sb, cold: cold)
    case .c32: return Screen32(sb: sb, cold: cold)
    }
}
