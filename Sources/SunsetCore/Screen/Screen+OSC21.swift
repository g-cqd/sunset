/// OSC 21 (kitty colour control protocol — T-1 / t183): sets, resets, and queries named palette & dynamic colours
/// (`foreground`, `background`, `cursor`, `color0`..`color255`) in one semicolon-separated `key=value` string.
extension Screen {
    /// Dispatches `OSC 21 ; key=val ; key=? ; key= ... ST|BEL`.
    mutating func kittyColorControl(from start: Int, _ terminator: StringTerminator) {
        var index = start
        var repliesList: [(name: String, color: RGB?)] = []
        var mutated = false
        while let field = nextField(&index) {
            guard !field.isEmpty else { continue }
            guard let eq = oscBuffer[field].firstIndex(of: 0x3D) else { continue }
            let rawName = String(decoding: oscBuffer[field.lowerBound ..< eq], as: UTF8.self)
            let valueRange = oscBuffer.index(after: eq) ..< field.upperBound
            guard let slot = Self.kittyColorSlot(named: rawName) else { continue }
            if valueRange.count == 1, oscBuffer[valueRange.lowerBound] == 0x3F {
                repliesList.append((rawName, paletteColor(for: slot)))
            } else if valueRange.isEmpty {
                resetPaletteColor(for: slot)
                mutated = true
            } else if let color = Palette.parse(oscBuffer[valueRange]) {
                setPaletteColor(color, for: slot)
                mutated = true
            }
        }
        if mutated { markDirty(0 ... rows - 1) }
        guard !repliesList.isEmpty else { return }
        reportKittyColors(repliesList, terminator)
    }

    private enum KittyColorSlot {
        case foreground, background, cursor
        case indexed(Int)
    }

    private static func kittyColorSlot(named raw: String) -> KittyColorSlot? {
        switch raw {
            case "foreground": return .foreground
            case "background": return .background
            case "cursor": return .cursor
            default:
                guard raw.hasPrefix("color"), let index = Int(raw.dropFirst(5)), (0 ..< 256).contains(index) else {
                    return nil
                }
                return .indexed(index)
        }
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

    private mutating func reportKittyColors(_ entries: [(name: String, color: RGB?)], _ terminator: StringTerminator) {
        var bytes: [UInt8] = Array("\u{1B}]21".utf8)
        for entry in entries {
            bytes.append(0x3B)
            bytes.append(contentsOf: entry.name.utf8)
            bytes.append(0x3D)
            if let color = entry.color {
                bytes.append(contentsOf: "rgb:".utf8)
                Self.appendHex16(color.red, to: &bytes)
                bytes.append(0x2F)
                Self.appendHex16(color.green, to: &bytes)
                bytes.append(0x2F)
                Self.appendHex16(color.blue, to: &bytes)
            }
        }
        if terminator == .bel { bytes.append(0x07) } else { bytes.append(contentsOf: [0x1B, 0x5C]) }
        guard replies.count + bytes.count <= Self.replyLimit else {
            droppedReplies += 1
            return
        }
        replies.append(contentsOf: bytes)
    }

    private static func appendHex16(_ value: UInt8, to out: inout [UInt8]) {
        let digits: [UInt8] = Array("0123456789abcdef".utf8)
        let high = digits[Int(value >> 4)]
        let low = digits[Int(value & 15)]
        out.append(contentsOf: [high, low, high, low])
    }
}
