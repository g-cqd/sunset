/// The styles in use on a screen, interned: a cell holds the 16-bit id. Id 0 is the default style. Entries are not reference-counted (a cell write
/// must not pay for it); when the table is full the screen rebuilds it from the cells that are still on screen (`Screen.compactStyles`).
struct StyleTable: Sendable {
    static let capacity = 1 << 16

    private(set) var styles: ContiguousArray<CellStyle> = [CellStyle()]
    private var ids: [CellStyle: UInt16] = [CellStyle(): 0]

    var count: Int { styles.count }

    subscript(id: UInt16) -> CellStyle { styles[Int(id)] }

    /// The id of `style`, adding it if new; nil when the table is full.
    mutating func intern(_ style: CellStyle) -> UInt16? {
        if let id = ids[style] { return id }
        guard styles.count < Self.capacity else { return nil }
        let id = UInt16(styles.count)
        styles.append(style)
        ids[style] = id
        return id
    }
}
