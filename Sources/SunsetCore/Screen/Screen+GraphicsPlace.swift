/// Images put on the screen and taken off it (ADR-0117).
extension Screen {
    mutating func place(_ command: KittyCommand) {
        guard placeImage(UInt32(clamping: command.int("i")), command) else { return kittyReply(command, .noEntry) }
        kittyReply(command, nil)
    }

    /// Puts image `id` at the cursor, over the cells its pixels cover (or `c` columns and `r` rows), on its line, and moves
    /// the cursor after it, as text would be, unless `C=1`. False when there is no such image.
    @discardableResult
    mutating func placeImage(_ id: UInt32, _ command: KittyCommand) -> Bool {
        guard let image = graphics.images[id] else { return false }
        let across = Self.cells(command.int("c"), image.width, graphics.cellWidth)
        let down = Self.cells(command.int("r"), image.height, graphics.cellHeight)
        let placement = ImagePlacement(
            image: id,
            placement: UInt32(clamping: command.int("p")),
            stableLine: cursorStableLine,
            column: column,
            columns: across,
            rows: down,
            layer: command.int("z")
        )
        graphics.place(placement)
        markDirty(row ... min(row + down - 1, rows - 1))
        guard command.int("C") != 1 else { return true }
        let start = column
        for _ in 0 ..< down - 1 { lineFeed() }
        column = min(start + across, columns - 1)
        pendingWrap = false
        return true
    }

    /// The cells a side takes: as given, else as many as its pixels cover; at least one, at most the side limit.
    private static func cells(_ given: Int, _ pixels: Int, _ cell: Int) -> Int {
        let count = given > 0 ? given : (pixels + max(cell, 1) - 1) / max(cell, 1)
        return min(max(count, 1), TerminalGraphics.sideLimit)
    }

    /// `d`: `a` every placement, `i` those of image `i` (and placement `p`, when given); in capitals the images go too.
    mutating func deleteImages(_ command: KittyCommand) {
        let what = command.letter("d", or: "a")
        let frees = what >= UInt8(ascii: "A") && what <= UInt8(ascii: "Z")
        switch what | 0x20 {
            case UInt8(ascii: "a"):
                if frees { graphics.clear() } else { graphics.placements = [] }
            case UInt8(ascii: "i"):
                let id = UInt32(clamping: command.int("i"))
                let placement = UInt32(clamping: command.int("p"))
                if frees {
                    graphics.remove(image: id)
                } else {
                    graphics.placements.removeAll { $0.image == id && (placement == 0 || $0.placement == placement) }
                }
            default:
                return
        }
        markDirty(0 ... rows - 1)
    }
}
