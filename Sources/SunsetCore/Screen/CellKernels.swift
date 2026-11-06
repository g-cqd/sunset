internal import CSunsetKernels

/// Row-sized operations on cells, in C with vector instructions where it pays.
enum CellKernels {
    /// How many leading cells of `cells` matter: up to and including the last one that is not the empty cell (raw word 0).
    static func usedLength(_ cells: UnsafeBufferPointer<Cell>) -> Int {
        guard let base = cells.baseAddress else { return 0 }
        return unsafe base.withMemoryRebound(to: UInt64.self, capacity: cells.count) {
            Int(unsafe sunset_used_length_u64($0, cells.count))
        }
    }

    static func usedLengthScalar(_ cells: UnsafeBufferPointer<Cell>) -> Int {
        guard let base = cells.baseAddress else { return 0 }
        return unsafe base.withMemoryRebound(to: UInt64.self, capacity: cells.count) {
            Int(unsafe sunset_used_length_u64_scalar($0, cells.count))
        }
    }
}
