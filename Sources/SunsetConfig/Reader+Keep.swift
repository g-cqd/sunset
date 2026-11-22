internal import OrderedCollections

extension Reader {
    /// `web.keep`: what WebKit keeps between runs.
    mutating func readKeep(_ object: Object) {
        // Every key is a plain value its option reads; anything else is not one.
        for key in object.keys {
            unknown("web.keep.\(key)")
        }
    }
}
