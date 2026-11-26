import AemiKernel

/// The kitty graphics protocol (`APC G ... ST`) and Sixel DCS (`DCS P1;P2;P3 q ... ST`) string collection on `Screen`:
/// shares one bounded buffer since APC and DCS strings never overlap in the VT parser.
extension Screen {
    mutating func graphicsStart(
        _ kind: StringKind,
        parameters: Parameters,
        marker: UInt8,
        intermediates: Intermediates,
        final: UInt8
    ) {
        if kind == .apc {
            graphics.collectingKind = .kitty
        } else if kind == .dcs, final == UInt8(ascii: "q"), marker == 0, intermediates.count == 0 {
            graphics.collectingKind = .sixel
            graphics.sixelTransparent = parameters[1] == 1
        } else {
            graphics.collectingKind = .none
        }
        graphics.overflowed = false
        // A large image's buffer is let go, not kept for every later command.
        if graphics.buffer.capacity > 1 << 16 {
            graphics.buffer = []
        } else {
            graphics.buffer.removeAll(keepingCapacity: true)
        }
    }

    mutating func graphicsAppend(_ bytes: Span<UInt8>) {
        guard graphics.collectingKind != .none, !graphics.overflowed else { return }
        let limit = graphics.collectingKind == .sixel ? TerminalGraphics.sixelLimit : TerminalGraphics.stringLimit
        guard graphics.buffer.count + bytes.count <= limit else {
            graphics.overflowed = true
            return
        }
        // In one copy: the span's memory, read within its bounds.
        bytes.withUnsafeBufferPointer { graphics.buffer.append(contentsOf: unsafe $0) }
    }

    mutating func graphicsEnd(completed: Bool) {
        let active = graphics.collectingKind
        guard active != .none else { return }
        graphics.collectingKind = .none
        guard completed, !graphics.overflowed, !graphics.buffer.isEmpty else { return }
        let bytes = Array(graphics.buffer)
        switch active {
            case .kitty:
                guard bytes.first == UInt8(ascii: "G"), let command = KittyCommand(bytes[1...]) else { return }
                kitty(command)
            case .sixel:
                finishSixel(bytes[...])
            case .none:
                break
        }
    }

    private mutating func kitty(_ command: KittyCommand) {
        if graphics.pending != nil { return transmitMore(command) }
        switch command.letter("a", or: "t") {
            case UInt8(ascii: "t"), UInt8(ascii: "T"), UInt8(ascii: "q"), UInt8(ascii: "f"): transmit(command)
            case UInt8(ascii: "a"): controlAnimation(command)
            case UInt8(ascii: "c"): composeFrame(command)
            case UInt8(ascii: "p"): place(command)
            case UInt8(ascii: "d"): deleteImages(command)
            default: kittyReply(command, .invalid)
        }
    }

    /// Answers `command`: OK, or `error`. Only a command that names its image (`i=` or `I=`) is answered; `q=1` keeps
    /// quiet on success, `q=2` always.
    mutating func kittyReply(_ command: KittyCommand, _ error: KittyError?, resolvedID: UInt32? = nil) {
        let (givenID, number, placement, quiet) = (
            command.int("i"), command.int("I"), command.int("p"), command.int("q")
        )
        let id = resolvedID.map { Int($0) } ?? givenID
        guard id > 0 || number > 0, quiet < 2, error != nil || quiet < 1 else { return }
        reply { writer in
            writer.text("\u{1B}_G")
            var wrote = false
            if id > 0 {
                writer.text("i=")
                writer.number(id)
                wrote = true
            }
            if number > 0 {
                if wrote { writer.text(",") }
                writer.text("I=")
                writer.number(number)
                wrote = true
            }
            if placement > 0 {
                if wrote { writer.text(",") }
                writer.text("p=")
                writer.number(placement)
            }
            writer.text(";")
            if let error { writer.text(error.message) } else { writer.text("OK") }
            writer.text("\u{1B}\\")
        }
    }
}
