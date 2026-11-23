/// The styles in use on a screen, interned: a cell holds the 16-bit id. Id 0 is the default style. Entries are not reference-counted (a cell write
/// must not pay for it); when the table is full the screen rebuilds it from the cells that are still on screen (`Screen.compactStyles`).
struct StyleTable: Sendable {
    static let capacity = Interned<CellStyle>.capacity

    private var table = Interned(none: CellStyle())

    var styles: ContiguousArray<CellStyle> {
        table.values
    }

    var count: Int {
        table.count
    }

    subscript(id: UInt16) -> CellStyle {
        styles[Int(id)]
    }

    /// The id of `style`, adding it if new; nil when the table is full.
    mutating func intern(_ style: CellStyle) -> UInt16? {
        table.intern(style)
    }

    /// Rewrites each style's link id through `map` (the link table compacted). Styles that become equal stay apart: a
    /// cell keeps its id.
    mutating func mapLinks(_ map: (UInt16) -> UInt16) {
        table.rewrite { $0.link = map($0.link) }
    }
}
