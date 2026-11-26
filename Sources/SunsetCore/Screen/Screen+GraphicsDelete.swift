/// Images taken off the screen (`a=d`, ADR-0117), as kitty does: by id (`i`), range of ids (`r`), and the placements on
/// the screen that meet a cell (`p`), the cursor's cell (`c`), a cell and a layer (`q`), a column (`x`), a row (`y`), a
/// layer (`z`), or all of them (`a`); an image's animation frames (`f`). Lowercase keeps the images; uppercase frees those left without a placement, and by
/// id or range the images named, shown or not. Any delete ends an upload in progress.
extension Screen {
    mutating func deleteImages(_ command: KittyCommand) {
        graphics.pending = nil
        let what = command.letter("d", or: "a")
        if what | 0x20 == UInt8(ascii: "f") { return deleteFrames(command) }
        guard Self.deletes.contains(what | 0x20) else { return }
        let deleted = graphics.placements.map { doomed($0, command) }
        let gone = Set(zip(graphics.placements, deleted).filter(\.1).map(\.0.image))
        graphics.placements = zip(graphics.placements, deleted).filter { !$0.1 }.map(\.0)
        // A virtual placement is on no cell of its own: only a delete by image, number, or range names it.
        let kept = graphics.virtualPlacements.filter {
            !matchesTarget(image: $0.image, placement: $0.placement, command)
        }
        graphics.virtualPlacements = kept
        if what >= UInt8(ascii: "A"), what <= UInt8(ascii: "Z") {
            for id in gone where !graphics.isShown(id) { graphics.remove(image: id) }
            for id in graphics.images.keys where named(id, command) { graphics.remove(image: id) }
        }
        markDirty(0 ... rows - 1)
    }

    private static let deletes = Set("incpqxyzra".utf8)

    /// `d=f`/`F`: the frames past the root of the image named by `i` or `I` go; the root is shown and the animation
    /// stops. Nothing named: nothing done.
    private mutating func deleteFrames(_ command: KittyCommand) {
        guard let id = graphics.resolveID(id: command.int("i"), number: command.int("I")),
            var image = graphics.images[id], var anim = image.animation
        else { return }
        anim.frames = []
        anim.currentFrame = 1
        anim.state = .stopped
        anim.loopBacks = 0
        anim.deadline = nil
        image.animation = anim
        _ = graphics.update(image)
        markShown(id)
    }

    private func matchesTarget(image: UInt32, placement: UInt32, _ command: KittyCommand) -> Bool {
        let p = UInt32(clamping: command.int("p"))
        let placementMatch = p == 0 || placement == p
        switch command.letter("d", or: "a") | 0x20 {
            case UInt8(ascii: "i"): return image == UInt32(clamping: command.int("i")) && placementMatch
            case UInt8(ascii: "n"):
                return graphics.images[image]?.number == UInt32(clamping: command.int("I")) && placementMatch
            case UInt8(ascii: "r"): return named(image, command)
            default: return false
        }
    }

    /// Whether `placement` is one `command` deletes.
    private func doomed(_ placement: ImagePlacement, _ command: KittyCommand) -> Bool {
        let (x, y) = (command.int("x") - 1, command.int("y") - 1)
        let span = span(of: placement)
        switch command.letter("d", or: "a") | 0x20 {
            case UInt8(ascii: "i"), UInt8(ascii: "n"), UInt8(ascii: "r"):
                return matchesTarget(image: placement.image, placement: placement.placement, command)
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

    /// Whether image `id` is named whole by `command`: by id/number with no placement number, or by range.
    private func named(_ id: UInt32, _ command: KittyCommand) -> Bool {
        switch command.letter("d", or: "a") | 0x20 {
            case UInt8(ascii: "i"): return command.int("p") == 0 && id == UInt32(clamping: command.int("i"))
            case UInt8(ascii: "n"):
                return command.int("p") == 0 && graphics.images[id]?.number == UInt32(clamping: command.int("I"))
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
