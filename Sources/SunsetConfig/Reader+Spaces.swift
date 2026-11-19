internal import OrderedCollections

extension Reader {
    /// `spaces` (roadmap 0044): every key is a plain value its option reads (`favorites`, `pinned`); anything else is not one.
    mutating func readSpaces(_ object: Object) {
        for key in object.keys {
            unknown("spaces.\(key)")
        }
    }
}
