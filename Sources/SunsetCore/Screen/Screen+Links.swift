/// Hyperlinks (OSC 8, ADR-0010): `8 ; params ; address` starts a link, an empty address ends it. The link is part of the style of the cells written
/// while it is open (kept apart from the pen, so that a reset of the colours does not end it). Parameters (`id=`) are ignored.
extension Screen {
    /// The address of the link a cell belongs to, or nil.
    public func link(of cell: Cell) -> String? { links[styles[cell.styleID].link] }

    public func link(row: Int, column: Int) -> String? { link(of: grid[row, column]) }

    public func viewportLink(row: Int, column: Int, scrolledBack: Int) -> String? {
        link(of: viewportCell(row: row, column: column, scrolledBack: scrolledBack))
    }

    mutating func hyperlink(from payload: Int) {
        var index = payload
        guard nextField(&index) != nil, index <= oscBuffer.count else { return }
        let address = oscBuffer[index...]
        setLink(address.isEmpty ? 0 : linkID(for: address))
    }

    private mutating func linkID(for bytes: ArraySlice<UInt8>) -> UInt16 {
        guard bytes.count <= LinkTable.addressLimit, !bytes.contains(where: { $0 < 0x20 || $0 == 0x7F }),
            let address = String(validating: bytes, as: UTF8.self)
        else { return 0 }
        return links.intern(address) ?? 0
    }

    private mutating func setLink(_ id: UInt16) {
        guard id != penLink else { return }
        penLink = id
        penChanged()
    }
}
