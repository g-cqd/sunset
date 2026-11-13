/// What reading a kept file gave: nothing was there, its value, or a file that did not read (moved aside, to be said).
public enum StoredRead<Value> {
    case absent
    case value(Value)
    case damaged(StorageProblem)

    public var value: Value? {
        if case .value(let value) = self { return value }
        return nil
    }
}

extension StoredRead: Equatable where Value: Equatable {}
extension StoredRead: Sendable where Value: Sendable {}
