/// The kitty keyboard protocol's flag stack for one screen: the main and the alternate screen each have their own.
struct KeyboardState: Sendable {
    /// How many pushes are remembered; the oldest is dropped beyond this.
    static let depth = 16

    /// Flags in force when nothing has been pushed.
    var base: UInt8 = 0
    var stack = ContiguousArray<UInt8>()

    var flags: UInt8 { stack.last ?? base }

    mutating func push(_ flags: UInt8) {
        if stack.count == Self.depth { stack.removeFirst() }
        stack.append(flags)
    }

    mutating func pop(_ count: Int) {
        stack.removeLast(min(count, stack.count))
    }

    /// `CSI = flags ; mode u`: 1 replaces, 2 adds the given bits, 3 removes them.
    mutating func set(_ value: UInt8, mode: Int) {
        let current = flags
        let updated: UInt8
        switch mode {
            case 2: updated = current | value
            case 3: updated = current & ~value
            default: updated = value
        }
        if stack.isEmpty { base = updated } else { stack[stack.count - 1] = updated }
    }
}

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
