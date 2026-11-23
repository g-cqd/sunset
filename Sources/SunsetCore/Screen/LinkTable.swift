/// The addresses of the hyperlinks on a screen, interned: a cell's style holds the 16-bit id (0 is no link). Bounded: when
/// 65 535 distinct addresses are held, the screen forgets those no cell uses any more (`Screen.compactLinks`).
struct LinkTable: Sendable {
    static let capacity = Interned<String>.capacity
    /// The longest address kept, in bytes (the usual limit of browsers and of the OSC 8 specification's recommendation).
    static let addressLimit = 2083

    private var table = Interned(none: "")

    var addresses: ContiguousArray<String> {
        table.values
    }

    subscript(id: UInt16) -> String? {
        id == 0 ? nil : addresses[Int(id)]
    }

    mutating func intern(_ address: String) -> UInt16? {
        table.intern(address)
    }
}
