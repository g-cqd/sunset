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
        let size = Self.size(of: image, columns: command.int("c"), rows: command.int("r"), graphics)
        let (across, down) = (size.cells.columns, size.cells.rows)
        let before = graphics.placements.count
        let placement = ImagePlacement(
            image: id,
            placement: UInt32(clamping: command.int("p")),
            stableLine: cursorStableLine,
            column: column,
            columns: across,
            rows: down,
            width: size.pixels.width,
            height: size.pixels.height,
            layer: command.int("z")
        )
        graphics.place(placement)
        // A placement that replaced another, or pushed the oldest out, leaves pixels elsewhere to redraw.
        let redraw = graphics.placements.count != before + 1 ? 0 : row
        markDirty(redraw ... min(row + down - 1, rows - 1))
        guard command.int("C") != 1 else { return true }
        let start = column
        for _ in 0 ..< down - 1 { lineFeed() }
        column = min(start + across, columns - 1)
        pendingWrap = false
        return true
    }

    /// The cells `image` takes and its size in pixels: its own, over the cells it covers; stretched over `columns` ×
    /// `rows` cells when both are given; scaled to the one given, keeping its proportions, as kitty does.
    static func size(of image: TerminalImage, columns: Int, rows: Int, _ graphics: TerminalGraphics) -> (
        cells: (columns: Int, rows: Int), pixels: (width: Int, height: Int)
    ) {
        let (cellWidth, cellHeight) = (max(graphics.cellWidth, 1), max(graphics.cellHeight, 1))
        var (width, height) = (image.width, image.height)
        if columns > 0, rows > 0 {
            (width, height) = (columns * cellWidth, rows * cellHeight)
        } else if columns > 0 {
            width = columns * cellWidth
            height = max((image.height * width + image.width / 2) / image.width, 1)
        } else if rows > 0 {
            height = rows * cellHeight
            width = max((image.width * height + image.height / 2) / image.height, 1)
        }
        let limit = TerminalGraphics.sideLimit
        let across = columns > 0 ? columns : (width + cellWidth - 1) / cellWidth
        let down = rows > 0 ? rows : (height + cellHeight - 1) / cellHeight
        return ((min(max(across, 1), limit), min(max(down, 1), limit)), (min(width, limit), min(height, limit)))
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
