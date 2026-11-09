/// The terminal's screen: a grid of cells, the cursor, the modes that shape editing, the scroll region and the alternate screen. It is the sink the
/// parser feeds (`Screen+Sink.swift`). The screen is the truth; whoever draws it reads it and keeps its own caches (ADR-0024).
public struct Screen: Sendable {
    public internal(set) var columns: Int
    public internal(set) var rows: Int

    var grid: Grid
    /// Lines that scrolled off the top of the primary screen, oldest first (the cold, compressed form is ADR-0013, later).
    var scrollback: Scrollback
    /// The other screen: the alternate one while the primary is shown, and the reverse.
    var other: Grid
    public internal(set) var isAlternate = false
    var styles = StyleTable()
    var clusters: ClusterTable
    /// Where the last character was written, so that a combining mark or joiner arriving next can join it. Any control, escape or control sequence in
    /// between ends the chance.
    var lastHead = (row: 0, column: 0)
    var joinable = false
    /// The last scalar absorbed was a zero-width joiner: the next scalar belongs to the cluster too.
    var afterJoiner = false

    var column = 0
    var row = 0
    var pendingWrap = false
    var pen = CellStyle()
    /// The link open now (OSC 8); part of the style of the cells written, but not of the pen: resetting the colours does not end it.
    var penLink: UInt16 = 0
    var links = LinkTable()
    var penID: UInt16 = 0
    var penIDIsCurrent = true
    /// The style of cells that erasing makes: only the pen's background (back-colour erase).
    var eraseID: UInt16 = 0
    var eraseIDIsCurrent = true
    var top = 0
    var bottom: Int
    var tabStops: ContiguousArray<Bool>
    var lastPrinted: UInt32 = 0
    var charsets: (g0: Charset, g1: Charset) = (.ascii, .ascii)
    /// 0 when G0 is shifted in (SI), 1 for G1 (SO).
    var shifted = false
    var saved: SavedCursor?
    var savedBeforeAlternate: SavedCursor?

    /// The modes the program has set; the host reads the ones that shape input (`Modes`).
    public internal(set) var modes = Modes()
    /// The window title and icon label set by the program (control characters removed), and the colours it can read and change.
    public internal(set) var titleBytes = ContiguousArray<UInt8>()
    public internal(set) var iconBytes = ContiguousArray<UInt8>()
    public internal(set) var palette = Palette()
    var titleStack = ContiguousArray<ContiguousArray<UInt8>>()
    var oscBuffer = ContiguousArray<UInt8>()
    var oscActive = false
    var host = HostState()
    var oscOverflowed = false
    public internal(set) var cursorShape = CursorShape.block
    public internal(set) var cursorBlinks = true
    /// The style the host wants (`Terminal.setDefaultCursor`): what DECSCUSR 0 and the resets go back to, and what the cursor is until a program chooses.
    var defaultCursor: (shape: CursorShape, blinks: Bool) = (.block, true)
    /// A program set the style itself (DECSCUSR 1 to 6), so a later change of the default does not undo it.
    var cursorChosen = false

    /// What changed since the last `clearDirty`, kept by physical row of the grid (`Grid.rowMap`), so that a scroll, which rotates the row map, carries it for
    /// nothing: whether the row was written (or blanked), and the screen row it was at. A screen row is dirty when its physical row was written or now sits
    /// elsewhere (`isDirty(row:)`, `movedFrom(row:)`). (With a second array kept by screen row and rotated with the row map, vtebench's scrolling of
    /// one-character lines was 15-22 % slower.)
    var writtenRows: ContiguousArray<Bool>
    var rowOrigins: ContiguousArray<Int32>
    public internal(set) var generation: UInt64 = 0
    public internal(set) var bellCount = 0

    struct SavedCursor: Sendable {
        var column: Int
        var row: Int
        var pendingWrap: Bool
        var pen: CellStyle
        var originMode: Bool
        var charsets: (g0: Charset, g1: Charset)
        var shifted: Bool
    }

    public init(columns: Int, rows: Int, scrollbackLimit: Int = 10_000, clusterLimit: Int = 1 << 20) {
        clusters = ClusterTable(limit: clusterLimit)
        precondition(columns > 0 && rows > 0, "a screen has at least one cell")
        self.columns = columns
        self.rows = rows
        grid = Grid(columns: columns, rows: rows)
        scrollback = Scrollback(columns: columns, limit: scrollbackLimit)
        other = Grid(columns: columns, rows: rows)
        bottom = rows - 1
        tabStops = Screen.defaultTabStops(columns)
        writtenRows = ContiguousArray(repeating: true, count: rows)
        rowOrigins = ContiguousArray(0 ..< Int32(rows))
        replies.reserveCapacity(256)
    }

    static func defaultTabStops(_ columns: Int) -> ContiguousArray<Bool> {
        ContiguousArray((0 ..< columns).map { $0 > 0 && $0 % 8 == 0 })
    }

    // MARK: Reading

    /// The kitty keyboard protocol flags in force on the screen shown.
    public var keyboardFlags: UInt8 { keyboard.flags }
    public internal(set) var droppedReplies = 0
    /// Answers waiting for the host (`Terminal.takeReplies`), bounded by `replyLimit`.
    var replies = ContiguousArray<UInt8>()
    var keyboard = KeyboardState()
    var otherKeyboard = KeyboardState()

    public var title: String { String(decoding: titleBytes, as: UTF8.self) }
    public var iconName: String { String(decoding: iconBytes, as: UTF8.self) }

    public var scrollbackCount: Int { scrollback.count }
    public func scrollbackCell(line: Int, column: Int) -> Cell { scrollback[line, column] }
    public func isScrollbackWrapped(line: Int) -> Bool { scrollback.isWrapped(line) }
    public func scrollbackText(line: Int) -> String {
        var scalars = String.UnicodeScalarView()
        for column in 0 ..< columns {
            appendText(of: scrollback[line, column], to: &scalars)
        }
        var text = String(scalars)
        while text.last == " " { text.removeLast() }
        return text
    }

    /// The directory the shell reported (OSC 7), the progress the program reported (OSC 9;4) and the prompt marks (OSC 133), oldest first.
    public var workingDirectory: WorkingDirectory? { host.workingDirectory }
    public var progress: ProgressState { host.progress }
    public var promptMarks: [PromptMark] { host.marks }

    public var cursorRow: Int { row }
    public var cursorColumn: Int { column }

    public func cell(row: Int, column: Int) -> Cell { grid[row, column] }
    public func style(of cell: Cell) -> CellStyle { styles[cell.styleID] }
    /// Every style, by id (`Cell.styleID`): for a renderer that reads many cells, so that it does not go through the screen for each (shared, not copied).
    public var cellStyles: ContiguousArray<CellStyle> { styles.styles }
    public func style(row: Int, column: Int) -> CellStyle { styles[grid[row, column].styleID] }
    /// Whether the line at `row` continues on the next one (it wrapped).
    public func isWrapped(row: Int) -> Bool { grid.wrapped[Int(grid.rowMap[row])] }

    /// The row as text: empty cells are spaces, the second half of a wide character is skipped, trailing spaces are dropped.
    public func text(row: Int) -> String {
        var scalars = String.UnicodeScalarView()
        for column in 0 ..< columns {
            let cell = grid[row, column]
            appendText(of: cell, to: &scalars)
        }
        var text = String(scalars)
        while text.last == " " { text.removeLast() }
        return text
    }

    /// The text of one cell: its character, or all the scalars of its cluster; a blank is a space and the second half of a wide character nothing.
    public func text(of cell: Cell) -> String {
        var scalars = String.UnicodeScalarView()
        appendText(of: cell, to: &scalars)
        return String(scalars)
    }

    func appendText(of cell: Cell, to scalars: inout String.UnicodeScalarView) {
        if cell.width == .spacerTail || cell.width == .spacerHead { return }
        if cell.isCluster {
            for value in clusters.scalars(of: cell.scalar) { scalars.append(Unicode.Scalar(value) ?? "\u{FFFD}") }
        } else {
            scalars.append(Unicode.Scalar(cell.scalar == 0 ? 0x20 : cell.scalar) ?? "\u{FFFD}")
        }
    }

    // MARK: Dirty rows (what a renderer must redraw, ADR-0024)

    public func isDirty(row: Int) -> Bool {
        let physical = Int(grid.rowMap[row])
        return writtenRows[physical] || rowOrigins[physical] != Int32(row)
    }

    public var hasDirtyRows: Bool { (0 ..< rows).contains { isDirty(row: $0) } }

    /// Marks every row clean: the renderer has taken what it needed.
    public mutating func clearDirty() {
        for row in 0 ..< rows {
            let physical = Int(grid.rowMap[row])
            writtenRows[physical] = false
            rowOrigins[physical] = Int32(row)
        }
    }

    mutating func markDirty(_ row: Int) {
        writtenRows[Int(grid.rowMap[row])] = true
        generation &+= 1
    }

    mutating func markDirty(_ range: ClosedRange<Int>) {
        let map = grid.rowMap
        writtenRows.withUnsafeMutableBufferPointer { written in
            for row in range { written[Int(map[row])] = true }
        }
        generation &+= 1
    }
}
