internal import AemiKernel

/// OSC 21, kitty's colour control protocol (T-1 / t183), per its spec (sw.kovidgoyal.net/kitty/color-stack, read
/// 2026-11-26): `OSC 21 ; key=value ; ... ST`. Sunset knows `foreground`, `background`, `cursor` and the palette's
/// `0`...`255`. `key=?` queries (answered `rgb:rr/gg/bb`), `key=<colour>` sets (`rgb:`, `#` forms), a bare `key` resets,
/// `key=` asks for a dynamic colour (Sunset has none: nothing changes, which the spec allows). Every other key, set or
/// queried, is answered `unknown=<its name in base64, without padding>`, so the escape cannot make Sunset echo text.
/// One answer holds the queries and unknowns in request order, with the request's terminator; none when there are none.
/// Not supported: X11 colour names, `rgbi:`, an alpha suffix (such a value is not read, and nothing changes).
extension Screen {
    mutating func kittyColorControl(from start: Int, _ terminator: StringTerminator) {
        var index = start
        var answers: [UInt8] = []
        var mutated = false
        while let field = nextField(&index) {
            let trimmed = Self.trimmingSpaces(field, in: oscBuffer)
            guard !trimmed.isEmpty else { continue }
            let equals = oscBuffer[trimmed].firstIndex(of: 0x3D)
            let key = trimmed.lowerBound ..< (equals ?? trimmed.upperBound)
            guard let slot = kittyColorSlot(Self.trimmingSpaces(key, in: oscBuffer)) else {
                Self.appendField(Array("unknown=".utf8) + Self.base64NoPadding(oscBuffer[key]), to: &answers)
                continue
            }
            guard let equals else {
                resetPaletteColor(for: slot)
                mutated = true
                continue
            }
            let value = Self.trimmingSpaces(oscBuffer.index(after: equals) ..< trimmed.upperBound, in: oscBuffer)
            if value.count == 1, oscBuffer[value.lowerBound] == 0x3F {
                Self.appendField(Array(oscBuffer[key]) + [0x3D] + Self.encoded(paletteColor(for: slot)), to: &answers)
            } else if !value.isEmpty, let color = Palette.parse(oscBuffer[value]) {
                setPaletteColor(color, for: slot)
                mutated = true
            }
        }
        if mutated { markDirty(0 ... rows - 1) }
        guard !answers.isEmpty else { return }
        let end: [UInt8] = terminator == .bel ? [0x07] : [0x1B, 0x5C]
        let reply: [UInt8] = [0x1B, 0x5D, 0x32, 0x31] + answers + end
        guard replies.count + reply.count <= Self.replyLimit else {
            droppedReplies += 1
            return
        }
        replies.append(contentsOf: reply)
    }

    enum KittyColorSlot {
        case foreground, background, cursor
        case indexed(Int)
    }

    /// The colour a key names: a special name, or a palette index written in decimal (`0`...`255`, no sign, no
    /// leading zero other than `0` itself).
    private func kittyColorSlot(_ key: Range<Int>) -> KittyColorSlot? {
        let name = oscBuffer[key]
        if name.elementsEqual("foreground".utf8) { return .foreground }
        if name.elementsEqual("background".utf8) { return .background }
        if name.elementsEqual("cursor".utf8) { return .cursor }
        guard (1 ... 3).contains(name.count), name.allSatisfy({ (0x30 ... 0x39).contains($0) }),
            name.count == 1 || name.first != 0x30
        else { return nil }
        let index = name.reduce(0) { $0 * 10 + Int($1 - 0x30) }
        return index < 256 ? .indexed(index) : nil
    }

    private func paletteColor(for slot: KittyColorSlot) -> RGB {
        switch slot {
            case .foreground: palette.foreground
            case .background: palette.background
            case .cursor: palette.cursor
            case .indexed(let index): palette.colors[index]
        }
    }

    private mutating func setPaletteColor(_ color: RGB, for slot: KittyColorSlot) {
        switch slot {
            case .foreground: palette.foreground = color
            case .background: palette.background = color
            case .cursor: palette.cursor = color
            case .indexed(let index): palette.colors[index] = color
        }
    }

    private mutating func resetPaletteColor(for slot: KittyColorSlot) {
        switch slot {
            case .foreground: palette.resetForeground()
            case .background: palette.resetBackground()
            case .cursor: palette.resetCursor()
            case .indexed(let index): palette.resetColor(index)
        }
    }

    /// `;` then `field`.
    private static func appendField(_ field: [UInt8], to answers: inout [UInt8]) {
        answers.append(0x3B)
        answers.append(contentsOf: field)
    }

    /// `rgb:rr/gg/bb`, lowercase.
    private static func encoded(_ color: RGB) -> [UInt8] {
        let digits = Array("0123456789abcdef".utf8)
        var out = Array("rgb:".utf8)
        for (offset, value) in [color.red, color.green, color.blue].enumerated() {
            if offset > 0 { out.append(0x2F) }
            out.append(digits[Int(value >> 4)])
            out.append(digits[Int(value & 0xF)])
        }
        return out
    }

    /// RFC 4648 base64 of `bytes`, without the `=` padding (the spec's form for `unknown`).
    private static func base64NoPadding(_ bytes: ArraySlice<UInt8>) -> [UInt8] {
        var encoded = Array(Base64.encodedString(Array(bytes)).utf8)
        while encoded.last == 0x3D { encoded.removeLast() }
        return encoded
    }

    /// `range` without the spaces around it.
    private static func trimmingSpaces(_ range: Range<Int>, in bytes: ContiguousArray<UInt8>) -> Range<Int> {
        var (low, high) = (range.lowerBound, range.upperBound)
        while low < high, bytes[low] == 0x20 { low += 1 }
        while high > low, bytes[high - 1] == 0x20 { high -= 1 }
        return low ..< high
    }
}
