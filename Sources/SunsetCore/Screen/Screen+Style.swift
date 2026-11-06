extension Screen {
    /// The id for the pen's style, interned on first use after it changed.
    mutating func currentPenID() -> UInt16 {
        if !penIDIsCurrent {
            penID = internStyle(pen)
            penIDIsCurrent = true
        }
        return penID
    }

    /// The id of the style of erased cells: the pen's background only.
    mutating func currentEraseID() -> UInt16 {
        if !eraseIDIsCurrent {
            var style = CellStyle()
            style.background = pen.background
            eraseID = internStyle(style)
            eraseIDIsCurrent = true
        }
        return eraseID
    }

    mutating func penChanged() {
        penIDIsCurrent = false
        eraseIDIsCurrent = false
    }

    private mutating func internStyle(_ style: CellStyle) -> UInt16 {
        if let id = styles.intern(style) { return id }
        compactStyles()
        // After compaction at most one id per cell on both screens is live, far below the capacity.
        return styles.intern(style) ?? 0
    }

    /// Rebuilds the style table from the styles the cells still use, and rewrites the cells' ids. The screens come first and always keep their styles;
    /// the history comes after, newest line first, and once the table is three quarters full its older lines lose their styles (default) instead of
    /// the table filling up again at once. That bounds the cost: a rebuild happens at most once per 16 384 new styles.
    mutating func compactStyles() {
        var remap = [UInt16?](repeating: nil, count: StyleTable.capacity)
        var fresh = StyleTable()
        let old = styles
        let historyLimit = StyleTable.capacity * 3 / 4
        func map(_ id: UInt16, history: Bool) -> UInt16 {
            if id == 0 { return 0 }
            if let mapped = remap[Int(id)] { return mapped }
            if history, fresh.count >= historyLimit { return 0 }
            let mapped = fresh.intern(old[id]) ?? 0
            remap[Int(id)] = mapped
            return mapped
        }
        for index in grid.cells.indices {
            grid.cells[index] = grid.cells[index].withStyle(map(grid.cells[index].styleID, history: false))
        }
        for index in other.cells.indices {
            other.cells[index] = other.cells[index].withStyle(map(other.cells[index].styleID, history: false))
        }
        scrollback.mapStyles { map($0, history: true) }
        styles = fresh
        penIDIsCurrent = false
        eraseIDIsCurrent = false
    }
}
