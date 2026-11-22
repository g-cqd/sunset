import AemiKernel

/// Images received (ADR-0117): only from data in the escape itself, as sent or compressed (`o=z`, through the host's
/// inflater); in one command or in chunks.
extension Screen {
    mutating func transmit(_ command: KittyCommand) {
        guard command.letter("t", or: "d") == UInt8(ascii: "d") else { return kittyReply(command, .forbidden) }
        let compression = command.letter("o", or: " ")
        guard compression == UInt8(ascii: " ") || compression == UInt8(ascii: "z") else {
            return kittyReply(command, .invalid)
        }
        guard let data = Base64.decode(command.payload) else { return kittyReply(command, .invalid) }
        if command.int("m") == 1 {
            graphics.pending = (command, data)
            return
        }
        finish(command, data)
    }

    /// A chunk of a command sent in chunks: its data added; the last one (`m=0`) finishes it.
    mutating func transmitMore(_ chunk: KittyCommand) {
        // Only what is needed is read of what is pending: a copy of it held here would make every chunk's append copy all
        // the data so far (measured: a 4 MiB image in 1,303 chunks took 78 ms).
        guard let command = graphics.pending?.command, let received = graphics.pending?.data.count else { return }
        guard let more = Base64.decode(chunk.payload) else {
            graphics.pending = nil
            return kittyReply(command, .invalid)
        }
        guard received + more.count <= graphics.quota else {
            graphics.pending = nil
            return kittyReply(command, .noSpace)
        }
        graphics.pending?.data.append(contentsOf: more)
        guard chunk.int("m") != 1, let whole = graphics.pending else { return }
        graphics.pending = nil
        finish(whole.command, whole.data)
    }

    /// The image read and kept (`t`), put at the cursor too (`T`), or only checked (`q`); then answered.
    private mutating func finish(_ command: KittyCommand, _ sent: [UInt8]) {
        let data: [UInt8]
        switch inflated(command, sent) {
            case .success(let read): data = read
            case .failure(let error): return kittyReply(command, error)
        }
        let action = command.letter("a", or: "t")
        let given = command.int("i")
        let id = given > 0 ? UInt32(clamping: given) : UInt32.max - UInt32(truncatingIfNeeded: graphics.stored)
        let image: TerminalImage
        switch Self.image(command, data, id: id, order: graphics.nextOrder()) {
            case .success(let read): image = read
            case .failure(let error): return kittyReply(command, error)
        }
        guard action != UInt8(ascii: "q") else { return kittyReply(command, nil) }
        let shown = graphics.placements.count
        guard graphics.store(image) else { return kittyReply(command, .noSpace) }
        // Placements of the image it replaced, or of those the quota sent away, went with them: their pixels are drawn over.
        if graphics.placements.count != shown { markDirty(0 ... rows - 1) }
        if action == UInt8(ascii: "T") { placeImage(image.id, command) }
        kittyReply(command, nil)
    }

    /// The image `data` holds, by its format (`f`): RGB (24), RGBA (32, the default) of the size given (`s`, `v`), or PNG
    /// (100) of the size its header says.
    private static func image(_ command: KittyCommand, _ data: [UInt8], id: UInt32, order: UInt64) -> Result<
        TerminalImage, KittyError
    > {
        let sides = 1 ... TerminalGraphics.sideLimit
        switch command.int("f", or: 32) {
            case 24, 32:
                let (width, height) = (command.int("s"), command.int("v"))
                let channels = command.int("f", or: 32) == 24 ? 3 : 4
                guard sides.contains(width), sides.contains(height) else { return .failure(.invalid) }
                let needed = width * height * channels
                guard data.count >= needed else { return .failure(.noData) }
                let format: TerminalImage.Format = channels == 3 ? .rgb : .rgba
                let pixels = Array(data.prefix(needed))
                return .success(
                    TerminalImage(id: id, format: format, width: width, height: height, pixels: pixels, order: order)
                )
            case 100:
                guard let size = PNGHeader.size(data) else { return .failure(.noData) }
                guard sides.contains(size.width), sides.contains(size.height) else { return .failure(.invalid) }
                let image = TerminalImage(
                    id: id,
                    format: .png,
                    width: size.width,
                    height: size.height,
                    pixels: data,
                    order: order
                )
                return .success(image)
            default:
                return .failure(.invalid)
        }
    }

    /// The data as sent, or inflated when it came compressed: never past the size raw pixels must have, nor the quota (a
    /// PNG); a size past the quota is refused before any work.
    private func inflated(_ command: KittyCommand, _ sent: [UInt8]) -> Result<[UInt8], KittyError> {
        guard command.letter("o", or: " ") == UInt8(ascii: "z") else { return .success(sent) }
        guard let inflater = graphics.inflater else { return .failure(.invalid) }
        var limit = graphics.quota
        let format = command.int("f", or: 32)
        if format == 24 || format == 32 {
            let sides = 1 ... TerminalGraphics.sideLimit
            let (width, height) = (command.int("s"), command.int("v"))
            guard sides.contains(width), sides.contains(height) else { return .failure(.invalid) }
            let needed = width * height * (format == 24 ? 3 : 4)
            guard needed <= graphics.quota else { return .failure(.noSpace) }
            limit = needed
        }
        guard let out = inflater.inflate(sent, limit: limit) else { return .failure(.invalid) }
        return .success(out)
    }
}
