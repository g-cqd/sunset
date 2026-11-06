/// Grapheme clusters of more than one scalar (a letter and its accents, an emoji joined to others), interned: a cell holds the id. Ids start at 1.
/// Entries are never freed; the table is bounded by `limit` and a cluster that would not fit is dropped (the marks of it, never the base).
struct ClusterTable: Sendable {
    let limit: Int
    private var starts: ContiguousArray<Int32> = [0, 0]
    private var scalars = ContiguousArray<UInt32>()
    private var ids: [ContiguousArray<UInt32>: UInt32] = [:]

    init(limit: Int) { self.limit = limit }

    var count: Int { starts.count - 2 }

    func scalars(of id: UInt32) -> ArraySlice<UInt32> { scalars[Int(starts[Int(id)]) ..< Int(starts[Int(id) + 1])] }

    /// The id of the cluster of these scalars, adding it if new; nil when the table is full.
    mutating func intern(_ cluster: ContiguousArray<UInt32>) -> UInt32? {
        if let id = ids[cluster] { return id }
        guard count < limit else { return nil }
        let id = UInt32(starts.count - 1)
        scalars.append(contentsOf: cluster)
        starts.append(Int32(scalars.count))
        ids[cluster] = id
        return id
    }
}
