extension Screen {
    /// The longest OSC payload acted on; a longer one is dropped whole.
    static let oscLimit = 4096
    /// The most an OSC 52 payload may take (ADR-0010): 1 MiB of base64 and its prefix.
    static let clipboardLimit = (1 << 20) + 16
    /// How many saved titles the stack keeps.
    static let titleStackDepth = 10

    mutating func oscStart(_ kind: StringKind) {
        oscActive = kind == .osc
        oscOverflowed = false
        // A big clipboard payload's buffer is let go, not kept for every later title.
        if oscBuffer.capacity > 1 << 16 { oscBuffer = [] } else { oscBuffer.removeAll(keepingCapacity: true) }
    }

    mutating func oscAppend(_ bytes: Span<UInt8>) {
        guard oscActive, !oscOverflowed else { return }
        let total = oscBuffer.count + bytes.count
        guard total <= Self.oscLimit || (total <= Self.clipboardLimit && startsClipboard(adding: bytes)) else {
            oscOverflowed = true
            return
        }
        for index in bytes.indices { oscBuffer.append(bytes[index]) }
    }

    /// Whether the string being collected is OSC 52 (`52;`), the one code that may be longer than `oscLimit`.
    private func startsClipboard(adding bytes: Span<UInt8>) -> Bool {
        var prefix: [UInt8] = []
        for index in 0 ..< min(oscBuffer.count, 3) { prefix.append(oscBuffer[index]) }
        var index = 0
        while prefix.count < 3, index < bytes.count {
            prefix.append(bytes[index])
            index += 1
        }
        return prefix == [0x35, 0x32, 0x3B]
    }

    mutating func oscEnd(completed: Bool, terminator: StringTerminator) {
        guard oscActive else { return }
        oscActive = false
        guard completed, !oscOverflowed else { return }
        dispatchOSC(terminator)
    }

    /// `code ; payload`. Codes this terminal does not act on are ignored; the ones that reach outside the screen are in `Screen+OSCHost.swift` (ADR-0010).
    private mutating func dispatchOSC(_ terminator: StringTerminator) {
        var code = 0
        var index = 0
        while index < oscBuffer.count, oscBuffer[index] >= 0x30, oscBuffer[index] <= 0x39, code < 100_000 {
            code = code * 10 + Int(oscBuffer[index] - 0x30)
            index += 1
        }
        guard index > 0, index == oscBuffer.count || oscBuffer[index] == 0x3B else { return }
        // Past the end when the code has no payload (see `nextField`).
        let payload = index < oscBuffer.count ? index + 1 : oscBuffer.count + 1
        switch code {
            case 0:
                setTitle(from: payload, icon: true, window: true)
            case 1:
                setTitle(from: payload, icon: true, window: false)
            case 2:
                setTitle(from: payload, icon: false, window: true)
            case 4:
                paletteEntries(from: payload, terminator)
            case 104:
                resetPaletteEntries(from: payload)
            case 10, 11, 12:
                dynamicColors(code, from: payload, terminator)
            case 110: palette.resetForeground()
            case 111: palette.resetBackground()
            case 112: palette.resetCursor()
            default: hostOSC(code, from: payload)
        }
    }

    // MARK: Titles

    /// Copies the payload as a title without control characters (C0, DEL and C1 as UTF-8), into the buffers already held (no allocation once warm).
    private mutating func setTitle(from start: Int, icon: Bool, window: Bool) {
        if window { titleBytes.removeAll(keepingCapacity: true) }
        if icon { iconBytes.removeAll(keepingCapacity: true) }
        var index = start
        while index < oscBuffer.count {
            let byte = oscBuffer[index]
            index += 1
            if byte < 0x20 || byte == 0x7F { continue }
            if byte == 0xC2, index < oscBuffer.count, oscBuffer[index] >= 0x80, oscBuffer[index] <= 0x9F {
                index += 1
                continue
            }
            if window { titleBytes.append(byte) }
            if icon { iconBytes.append(byte) }
        }
    }

    /// CSI 22 t: save the title.
    mutating func pushTitle() {
        if titleStack.count == Self.titleStackDepth { titleStack.removeFirst() }
        titleStack.append(titleBytes)
    }

    /// CSI 23 t: restore the saved title (nothing when none is saved).
    mutating func popTitle() {
        if let saved = titleStack.popLast() { titleBytes = saved }
    }

    // MARK: Colours

    /// The next `;`-separated field of the payload starting at `index`, advancing past its separator. `index` past the end of the buffer means no
    /// payload at all (and after the last field it is set there), so `a;b` has two fields, `a;` two (the second empty) and nothing none.
    func nextField(_ index: inout Int) -> Range<Int>? {
        guard index <= oscBuffer.count else { return nil }
        let start = index
        while index < oscBuffer.count, oscBuffer[index] != 0x3B { index += 1 }
        let field = start ..< index
        index = index < oscBuffer.count ? index + 1 : oscBuffer.count + 1
        return field
    }

    func number(_ range: Range<Int>) -> Int? {
        guard !range.isEmpty, range.count <= 4 else { return nil }
        var value = 0
        for index in range {
            guard oscBuffer[index] >= 0x30, oscBuffer[index] <= 0x39 else { return nil }
            value = value * 10 + Int(oscBuffer[index] - 0x30)
        }
        return value
    }

    private func isQuery(_ range: Range<Int>) -> Bool { range.count == 1 && oscBuffer[range.lowerBound] == 0x3F }

    /// OSC 4: `index ; spec` pairs; `?` asks for the colour.
    private mutating func paletteEntries(from start: Int, _ terminator: StringTerminator) {
        var index = start
        while let first = nextField(&index), let second = nextField(&index) {
            guard let entry = number(first), entry < 256 else { continue }
            if isQuery(second) {
                reportColor(code: 4, entry: entry, palette.colors[entry], terminator)
            } else if let color = Palette.parse(oscBuffer[second]) {
                palette.colors[entry] = color
            }
        }
    }

    private mutating func resetPaletteEntries(from start: Int) {
        guard start < oscBuffer.count else {
            palette.resetColors()
            return
        }
        var index = start
        while let field = nextField(&index) {
            if let entry = number(field), entry < 256 { palette.resetColor(entry) }
        }
    }

    /// OSC 10/11/12: foreground, background, cursor; more fields continue with the next colour.
    private mutating func dynamicColors(_ first: Int, from start: Int, _ terminator: StringTerminator) {
        var slot = first
        var index = start
        while slot <= 12, let field = nextField(&index) {
            if isQuery(field) {
                reportColor(code: slot, entry: nil, dynamic(slot), terminator)
            } else if let color = Palette.parse(oscBuffer[field]) {
                switch slot {
                    case 10: palette.foreground = color
                    case 11: palette.background = color
                    default: palette.cursor = color
                }
            }
            slot += 1
        }
    }

    private func dynamic(_ slot: Int) -> RGB {
        switch slot {
            case 10: palette.foreground
            case 11: palette.background
            default: palette.cursor
        }
    }

    private mutating func reportColor(code: Int, entry: Int?, _ color: RGB, _ terminator: StringTerminator) {
        reply { writer in
            writer.text("\u{1B}]")
            writer.number(code)
            writer.byte(0x3B)
            if let entry {
                writer.number(entry)
                writer.byte(0x3B)
            }
            writer.text("rgb:")
            writer.hex16(color.red)
            writer.byte(0x2F)
            writer.hex16(color.green)
            writer.byte(0x2F)
            writer.hex16(color.blue)
            if terminator == .bel { writer.byte(0x07) } else { writer.text("\u{1B}\\") }
        }
    }
}
