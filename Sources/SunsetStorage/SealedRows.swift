public import Foundation

/// The sealed bytes of a table's records as the file holds them, with what opens them (R12 step ST-3). Read from the database
/// on the main actor, in a few milliseconds; opened anywhere: at once for a small table, or on every core, off the main actor,
/// for a large one (each record is sealed on its own).
public struct SealedRows: Sendable {
    struct Record: Sendable {
        let index: Data
        let bytes: Data
    }

    /// What one piece of the work gives: the records it opened, and the number each is ordered by.
    private struct Piece<Value: Sendable>: Sendable {
        var values: [Value] = []
        var sorts: [Double] = []
    }

    let records: [Record]
    let seal: Seal
    /// What is bound into every record's seal before what names it.
    let binding: Data

    public var count: Int {
        records.count
    }

    /// Opens every record now, on this thread, and makes each into what its owner holds; the highest `sort` first. `decode`
    /// gives nil for a record it cannot use, which is counted with those that did not open (altered or damaged: not given).
    /// - Complexity: O(the records' bytes), and a sort of the records.
    public func open<Value: Sendable>(_ decode: @Sendable (SealedTable.Row) -> Value?) -> (
        values: [Value], unreadable: Int
    ) {
        ordered([piece(0 ..< records.count, decode)])
    }

    /// The same, off the caller's actor, in pieces run at once on the cooperative pool.
    @concurrent
    public func openConcurrently<Value: Sendable>(
        _ decode: @escaping @Sendable (SealedTable.Row) -> Value?
    ) async -> (values: [Value], unreadable: Int) {
        // Pieces smaller than a core's share: the fast cores take more of them than the slow ones.
        let size = 1024
        let ranges = stride(from: 0, to: records.count, by: size).map { $0 ..< min($0 + size, records.count) }
        let pieces = await withTaskGroup(of: (Int, Piece<Value>).self) { group in
            for (number, range) in ranges.enumerated() {
                group.addTask { (number, piece(range, decode)) }
            }
            var made: [Int: Piece<Value>] = [:]
            for await (number, piece) in group { made[number] = piece }
            return ranges.indices.compactMap { made[$0] }
        }
        return ordered(pieces)
    }

    private func piece<Value: Sendable>(_ range: Range<Int>, _ decode: (SealedTable.Row) -> Value?) -> Piece<Value> {
        var piece = Piece<Value>()
        piece.values.reserveCapacity(range.count)
        piece.sorts.reserveCapacity(range.count)
        var bound = binding
        for record in records[range] {
            bound.removeSubrange(binding.count...)
            bound.append(record.index)
            guard let envelope = try? seal.open(record.bytes, binding: bound),
                let opened = StateDatabase.unwrap(envelope),
                let value = decode(SealedTable.Row(payload: opened.payload, sort: opened.sort, count: opened.count))
            else { continue }
            piece.values.append(value)
            piece.sorts.append(opened.sort)
        }
        return piece
    }

    /// Joins the pieces, the highest `sort` first; records of one `sort` stay in the file's order, so the order is the same
    /// at every read. Sorted on the numbers alone: comparing through the records copied one at each comparison (measured:
    /// 270 ms for 50,000).
    private func ordered<Value: Sendable>(_ pieces: [Piece<Value>]) -> (values: [Value], unreadable: Int) {
        var values: [Value] = []
        values.reserveCapacity(records.count)
        var keys: [(sort: Double, position: Int)] = []
        keys.reserveCapacity(records.count)
        for piece in pieces {
            for sort in piece.sorts { keys.append((sort, keys.count)) }
            values.append(contentsOf: piece.values)
        }
        keys.sort { $0.sort != $1.sort ? $0.sort > $1.sort : $0.position < $1.position }
        return (keys.map { values[$0.position] }, records.count - values.count)
    }

    /// What names each record whose `sort` meets `matches`: every record opened to read it.
    func indexes(where matches: (Double) -> Bool) -> [Data] {
        var bound = binding
        return records.compactMap { record in
            bound.removeSubrange(binding.count...)
            bound.append(record.index)
            guard let envelope = try? seal.open(record.bytes, binding: bound),
                let opened = StateDatabase.unwrap(envelope),
                matches(opened.sort)
            else { return nil }
            return record.index
        }
    }
}
