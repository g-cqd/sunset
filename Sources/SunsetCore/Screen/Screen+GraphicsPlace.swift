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
        let part = Self.part(of: image, command, graphics)
        let size = Self.size(of: part, columns: command.int("c"), rows: command.int("r"), graphics)
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
            sourceX: part.x,
            sourceY: part.y,
            sourceWidth: part.width,
            sourceHeight: part.height,
            offsetX: part.offsetX,
            offsetY: part.offsetY,
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

    /// The part of `image` shown (`x`, `y`, `w`, `h`, within the image) and where it starts in its first cell (`X`, `Y`,
    /// within the cell).
    static func part(of image: TerminalImage, _ command: KittyCommand, _ graphics: TerminalGraphics) -> ImagePart {
        let x = min(max(command.int("x"), 0), image.width - 1)
        let y = min(max(command.int("y"), 0), image.height - 1)
        let (w, h) = (command.int("w"), command.int("h"))
        return ImagePart(
            x: x,
            y: y,
            width: w > 0 ? min(w, image.width - x) : image.width - x,
            height: h > 0 ? min(h, image.height - y) : image.height - y,
            offsetX: min(max(command.int("X"), 0), max(graphics.cellWidth - 1, 0)),
            offsetY: min(max(command.int("Y"), 0), max(graphics.cellHeight - 1, 0))
        )
    }

    /// The cells `part` takes and its size in pixels: its own, over the cells it covers from its offset; stretched over
    /// `columns` × `rows` cells when both are given; scaled to the one given, keeping its proportions, as kitty does.
    static func size(of part: ImagePart, columns: Int, rows: Int, _ graphics: TerminalGraphics) -> (
        cells: (columns: Int, rows: Int), pixels: (width: Int, height: Int)
    ) {
        let (cellWidth, cellHeight) = (max(graphics.cellWidth, 1), max(graphics.cellHeight, 1))
        var (width, height) = (part.width, part.height)
        if columns > 0, rows > 0 {
            (width, height) = (columns * cellWidth - part.offsetX, rows * cellHeight - part.offsetY)
        } else if columns > 0 {
            width = columns * cellWidth - part.offsetX
            height = max((part.height * width + part.width / 2) / part.width, 1)
        } else if rows > 0 {
            height = rows * cellHeight - part.offsetY
            width = max((part.width * height + part.height / 2) / part.height, 1)
        }
        let limit = TerminalGraphics.sideLimit
        let across = columns > 0 ? columns : (part.offsetX + width + cellWidth - 1) / cellWidth
        let down = rows > 0 ? rows : (part.offsetY + height + cellHeight - 1) / cellHeight
        return ((min(max(across, 1), limit), min(max(down, 1), limit)), (min(width, limit), min(height, limit)))
    }
}
