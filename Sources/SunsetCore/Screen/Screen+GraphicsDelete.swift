/// Images taken off the screen (`a=d`, ADR-0117), as kitty does: by id (`i`), range of ids (`r`), and the placements on
/// the screen that meet a cell (`p`), the cursor's cell (`c`), a cell and a layer (`q`), a column (`x`), a row (`y`), a
/// layer (`z`), or all of them (`a`). Lowercase keeps the images; uppercase frees those left without a placement, and by
/// id or range the images named, shown or not. Any delete ends an upload in progress.
extension Screen {
    mutating func deleteImages(_ command: KittyCommand) {
        graphics.pending = nil
        let what = command.letter("d", or: "a")
        guard Self.deletes.contains(what | 0x20) else { return }
        let deleted = graphics.placements.map { doomed($0, command) }
        let gone = Set(zip(graphics.placements, deleted).filter(\.1).map(\.0.image))
        graphics.placements = zip(graphics.placements, deleted).filter { !$0.1 }.map(\.0)
        if what >= UInt8(ascii: "A"), what <= UInt8(ascii: "Z") {
            for id in gone where !graphics.isShown(id) { graphics.remove(image: id) }
            for id in graphics.images.keys where named(id, command) { graphics.remove(image: id) }
        }
        markDirty(0 ... rows - 1)
    }

    private static let deletes = Set("icpqxyzra".utf8)

    /// Whether `placement` is one `command` deletes.
    private func doomed(_ placement: ImagePlacement, _ command: KittyCommand) -> Bool {
        let (x, y) = (command.int("x") - 1, command.int("y") - 1)
        let span = span(of: placement)
        switch command.letter("d", or: "a") | 0x20 {
            case UInt8(ascii: "i"):
                let number = UInt32(clamping: command.int("p"))
                return placement.image == UInt32(clamping: command.int("i"))
                    && (number == 0 || placement.placement == number)
            case UInt8(ascii: "r"): return named(placement.image, command)
            case UInt8(ascii: "a"): return span.rows.overlaps(0 ..< rows)
            case UInt8(ascii: "c"): return span.rows.contains(row) && span.columns.contains(column)
            case UInt8(ascii: "p"): return span.rows.contains(y) && span.columns.contains(x)
            case UInt8(ascii: "q"):
                return placement.layer == command.int("z") && span.rows.contains(y) && span.columns.contains(x)
            case UInt8(ascii: "x"): return span.columns.contains(x)
            case UInt8(ascii: "y"): return span.rows.contains(y)
            case UInt8(ascii: "z"): return placement.layer == command.int("z")
            default: return false
        }
    }

    /// Whether image `id` is named whole by `command`: by id with no placement number, or by range.
    private func named(_ id: UInt32, _ command: KittyCommand) -> Bool {
        switch command.letter("d", or: "a") | 0x20 {
            case UInt8(ascii: "i"): return command.int("p") == 0 && id == UInt32(clamping: command.int("i"))
            case UInt8(ascii: "r"):
                let low = UInt32(clamping: command.int("x"))
                return id >= low && id <= max(UInt32(clamping: command.int("y")), low)
            default: return false
        }
    }

    /// The screen rows (negative ones above it, in the history) and the columns a placement covers.
    private func span(of placement: ImagePlacement) -> (rows: Range<Int>, columns: Range<Int>) {
        let top = (absoluteLine(ofStable: placement.stableLine) ?? -placement.rows - 1) - scrollback.count
        return (top ..< top + placement.rows, placement.column ..< placement.column + placement.columns)
    }
}
