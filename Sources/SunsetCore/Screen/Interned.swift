/// Values interned by a 16-bit id, the first one standing for "none": the screen's styles and its links. Bounded at 65 536.
struct Interned<Value: Hashable & Sendable>: Sendable {
    static var capacity: Int {
        1 << 16
    }

    private(set) var values: ContiguousArray<Value>
    private var ids: [Value: UInt16]

    init(none: Value) {
        values = [none]
        ids = [none: 0]
    }

    var count: Int {
        values.count
    }

    /// The id of `value`, adding it if new; nil when the table is full.
    mutating func intern(_ value: Value) -> UInt16? {
        if let id = ids[value] { return id }
        guard values.count < Self.capacity else { return nil }
        let id = UInt16(values.count)
        values.append(value)
        ids[value] = id
        return id
    }

    /// Rewrites every value through `change`; values that become equal stay apart (an id held elsewhere keeps its value).
    mutating func rewrite(_ change: (inout Value) -> Void) {
        ids.removeAll(keepingCapacity: true)
        for index in values.indices {
            change(&values[index])
            if ids[values[index]] == nil { ids[values[index]] = UInt16(index) }
        }
    }
}
