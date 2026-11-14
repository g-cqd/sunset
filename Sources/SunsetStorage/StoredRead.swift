/// What reading a kept file gave: nothing was there, its value, a file that did not read (moved aside, to be said), or one
/// sealed with another key (left where it is, to be said, and not to be written over).
public enum StoredRead<Value> {
    case absent
    case value(Value)
    case damaged(StorageProblem)
    case locked(StorageProblem)

    public var value: Value? {
        if case .value(let value) = self { return value }
        return nil
    }

    /// What there is to say about it.
    public var problem: StorageProblem? {
        switch self {
            case .damaged(let problem), .locked(let problem): problem
            case .absent, .value: nil
        }
    }
}

extension StoredRead: Equatable where Value: Equatable {}
extension StoredRead: Sendable where Value: Sendable {}
