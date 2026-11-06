extension Screen {
    mutating func keyboardQuery() {
        let flags = Int(keyboard.flags)
        reply { writer in
            writer.text("\u{1B}[?")
            writer.number(flags)
            writer.byte(0x75)
        }
    }

    /// Flags are five bits (disambiguate, event types, alternates, all keys as escapes, associated text).
    mutating func keyboardPush(_ flags: Int) { keyboard.push(UInt8(truncatingIfNeeded: flags & 31)) }
    mutating func keyboardPop(_ count: Int) { keyboard.pop(count) }
    mutating func keyboardSet(_ flags: Int, mode: Int) {
        keyboard.set(UInt8(truncatingIfNeeded: flags & 31), mode: mode)
    }
}
