/// OSC 22: the shape of the mouse pointer over the screen. `22 ; name` (xterm) and `22 ; =name` set it, an empty name gives the terminal's own back;
/// `>name,name` pushes, `<` pops, `?name,name` asks (kitty): the answer is `1` or `0` for each name, or the name itself for `__current__`,
/// `__default__` and `__grabbed__`. A name that is not known changes nothing. Each of the two screens has its stack.
extension Screen {
    /// The shape the program asked for, nil for the terminal's own.
    public var pointerShape: PointerShape? { pointer.current }

    mutating func pointerShape(from start: Int, _ terminator: StringTerminator) {
        guard start < oscBuffer.count else {
            pointer.set(nil)
            return
        }
        let names = start + 1 ..< oscBuffer.count
        switch oscBuffer[start] {
            case 0x3D: setPointer(named: names)
            case 0x3E:
                for name in oscBuffer[names].split(separator: 0x2C) {
                    if let shape = PointerShape(name: name) { pointer.push(shape) }
                }
            case 0x3C: pointer.pop()
            case 0x3F: answerPointerQuery(names, terminator)
            default: setPointer(named: start ..< oscBuffer.count)
        }
    }

    private mutating func setPointer(named range: Range<Int>) {
        if range.isEmpty {
            pointer.set(nil)
        } else if let shape = PointerShape(name: oscBuffer[range]) {
            pointer.set(shape)
        }
    }

    private mutating func answerPointerQuery(_ names: Range<Int>, _ terminator: StringTerminator) {
        let asked = oscBuffer[names].split(separator: 0x2C, omittingEmptySubsequences: false)
        let current = pointer.current ?? .arrow
        reply { writer in
            writer.text("\u{1B}]22;")
            for (index, name) in asked.enumerated() {
                if index > 0 { writer.byte(0x2C) }
                if name.elementsEqual("__current__".utf8) {
                    for byte in current.rawValue.utf8 { writer.byte(byte) }
                } else if name.elementsEqual("__default__".utf8) || name.elementsEqual("__grabbed__".utf8) {
                    writer.text("default")
                } else {
                    writer.byte(PointerShape(name: name) == nil ? 0x30 : 0x31)
                }
            }
            if terminator == .bel { writer.byte(0x07) } else { writer.text("\u{1B}\\") }
        }
    }
}
