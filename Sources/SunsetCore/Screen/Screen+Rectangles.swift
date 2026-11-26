/// VT400 rectangular area operations (DECERA, DECFRA, DECCRA) and DECSET/DECRST reverse-wrap / mode-stack helpers
/// (T-4 / t219 esctest & vttest conformance).
extension Screen {
    /// DECERA (`CSI Pt ; Pl ; Pb ; Pr $ z`): erases the rectangular area to blank cells with the current erase style.
    mutating func eraseRectangle(_ parameters: Parameters) {
        let blank = Cell(scalar: 0, width: .narrow, style: currentEraseID())
        paintRectangle(from: parameters, at: 0, with: blank)
    }

    /// DECFRA (`CSI Pch ; Pt ; Pl ; Pb ; Pr $ x`): fills the rectangular area with `Pch` (printable ASCII 0x20...0x7E
    /// or 0xA0...0xFE) using the current pen style.
    mutating func fillRectangle(_ parameters: Parameters) {
        let ch = parameters[0]
        guard (0x20 ... 0x7E).contains(ch) || (0xA0 ... 0xFE).contains(ch) else { return }
        let cell = Cell(scalar: UInt32(ch), width: .narrow, style: currentPenID())
        paintRectangle(from: parameters, at: 1, with: cell)
    }

    private mutating func paintRectangle(from parameters: Parameters, at offset: Int, with cell: Cell) {
        guard let rect = rectangle(from: parameters, at: offset) else { return }
        for r in rect.top ... rect.bottom {
            clearWideEdges(row: r, from: rect.left, to: rect.right)
            grid.fill(row: r, from: rect.left, to: rect.right, with: cell)
        }
        markDirty(rect.top ... rect.bottom)
    }

    /// DECCRA (`CSI Pts ; Pls ; Pbs ; Prs ; Pps ; Ptd ; Pld ; Ppd $ v`): copies a rectangular area within page 1
    /// (handling overlapping source and destination safely via snapshot).
    mutating func copyRectangle(_ parameters: Parameters) {
        guard let src = rectangle(from: parameters, at: 0) else { return }
        let originRow = modes.origin ? top : 0
        let maxRow = modes.origin ? bottom : rows - 1
        let dstTop = originRow + max(parameters.value(5, default: 1) - 1, 0)
        let dstLeft = max(parameters.value(6, default: 1) - 1, 0)
        guard dstTop <= maxRow, dstLeft < columns else { return }
        let height = min(src.bottom - src.top + 1, maxRow - dstTop + 1)
        let width = min(src.right - src.left + 1, columns - dstLeft)
        guard height > 0, width > 0 else { return }

        var copied: [[Cell]] = []
        copied.reserveCapacity(height)
        for dy in 0 ..< height {
            var line: [Cell] = []
            line.reserveCapacity(width)
            for dx in 0 ..< width {
                line.append(grid[src.top + dy, src.left + dx])
            }
            copied.append(line)
        }
        for dy in 0 ..< height {
            let r = dstTop + dy
            clearWideEdges(row: r, from: dstLeft, to: dstLeft + width - 1)
            for dx in 0 ..< width {
                grid[r, dstLeft + dx] = copied[dy][dx]
            }
        }
        markDirty(dstTop ... dstTop + height - 1)
    }

    private struct CellRect {
        let top: Int
        let left: Int
        let bottom: Int
        let right: Int
    }

    /// Parses 1-based `(Pt, Pl, Pb, Pr)` starting at `offset` in `parameters`, respecting origin mode (`DECOM`).
    private func rectangle(from parameters: Parameters, at offset: Int) -> CellRect? {
        let minRow = modes.origin ? top : 0
        let maxRow = modes.origin ? bottom : rows - 1
        let rawTop = parameters[offset]
        let rawLeft = parameters[offset + 1]
        let rawBottom = parameters[offset + 2]
        let rawRight = parameters[offset + 3]
        let rTop = min(maxRow, minRow + max((rawTop == 0 ? 1 : rawTop) - 1, 0))
        let rLeft = min(columns - 1, max((rawLeft == 0 ? 1 : rawLeft) - 1, 0))
        let rBottom = rawBottom == 0 ? maxRow : min(maxRow, minRow + max(rawBottom - 1, 0))
        let rRight = rawRight == 0 ? columns - 1 : min(columns - 1, max(rawRight - 1, 0))
        guard rTop <= rBottom, rLeft <= rRight else { return nil }
        return CellRect(top: rTop, left: rLeft, bottom: rBottom, right: rRight)
    }
}
