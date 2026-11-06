/// The addresses of the hyperlinks on a screen, interned: a cell's style holds the 16-bit id (0 is no link). Bounded: past 65 535 distinct addresses new ones
/// are not recorded (their text is plain), while the known ones stay usable.
struct LinkTable: Sendable {
    static let capacity = 1 << 16
    /// The longest address kept, in bytes (the usual limit of browsers and of the OSC 8 specification's recommendation).
    static let addressLimit = 2083

    private(set) var addresses: ContiguousArray<String> = [""]
    private var ids: [String: UInt16] = [:]

    subscript(id: UInt16) -> String? { id == 0 ? nil : addresses[Int(id)] }

    mutating func intern(_ address: String) -> UInt16? {
        if let id = ids[address] { return id }
        guard addresses.count < Self.capacity else { return nil }
        let id = UInt16(addresses.count)
        addresses.append(address)
        ids[address] = id
        return id
    }
}
