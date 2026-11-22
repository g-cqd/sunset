import AemiKernel

/// The kitty graphics protocol's commands (ADR-0117), sent as APC strings starting with `G`: collected within a bound, read,
/// and answered as kitty answers.
extension Screen {
    mutating func graphicsStart(_ kind: StringKind) {
        graphics.collecting = kind == .apc
        graphics.overflowed = false
        // A large image's buffer is let go, not kept for every later command.
        if graphics.buffer.capacity > 1 << 16 {
            graphics.buffer = []
        } else {
            graphics.buffer.removeAll(keepingCapacity: true)
        }
    }

    mutating func graphicsAppend(_ bytes: Span<UInt8>) {
        guard graphics.collecting, !graphics.overflowed else { return }
        guard graphics.buffer.count + bytes.count <= TerminalGraphics.stringLimit else {
            graphics.overflowed = true
            return
        }
        // In one copy: the span's memory, read within its bounds.
        bytes.withUnsafeBufferPointer { graphics.buffer.append(contentsOf: unsafe $0) }
    }

    mutating func graphicsEnd(completed: Bool) {
        guard graphics.collecting else { return }
        graphics.collecting = false
        guard completed, !graphics.overflowed, graphics.buffer.first == UInt8(ascii: "G") else { return }
        let bytes = Array(graphics.buffer)
        guard let command = KittyCommand(bytes[1...]) else { return }
        kitty(command)
    }

    private mutating func kitty(_ command: KittyCommand) {
        if graphics.pending != nil { return transmitMore(command) }
        switch command.letter("a", or: "t") {
            case UInt8(ascii: "t"), UInt8(ascii: "T"), UInt8(ascii: "q"): transmit(command)
            case UInt8(ascii: "p"): place(command)
            case UInt8(ascii: "d"): deleteImages(command)
            default: kittyReply(command, .invalid)
        }
    }

    /// Answers `command`: OK, or `error`. Only a command that names its image is answered; `q=1` keeps quiet on success,
    /// `q=2` always.
    mutating func kittyReply(_ command: KittyCommand, _ error: KittyError?) {
        let (id, placement, quiet) = (command.int("i"), command.int("p"), command.int("q"))
        guard id > 0, quiet < 2, error != nil || quiet < 1 else { return }
        reply { writer in
            writer.text("\u{1B}_Gi=")
            writer.number(id)
            if placement > 0 {
                writer.text(",p=")
                writer.number(placement)
            }
            writer.text(";")
            if let error { writer.text(error.message) } else { writer.text("OK") }
            writer.text("\u{1B}\\")
        }
    }
}
