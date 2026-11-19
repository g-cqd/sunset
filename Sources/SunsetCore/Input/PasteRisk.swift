/// What a paste would do that the person may not see (task t116, white paper §9): asked about before it reaches the program.
public enum PasteRisk: Equatable, Sendable {
    /// Without bracketed paste each line ending is an Enter: `lines` commands would run as the paste lands.
    case runs(lines: Int)
    /// C0 or C1 control characters (but tab and line endings) and DEL: they act on the program, as Escape or Ctrl-C would.
    case controlCharacters
    /// Characters that hide or reorder text: what is shown is not what runs (bidirectional controls, zero-width
    /// characters, tags, the byte order mark, the soft hyphen).
    case hiddenCharacters

    /// What `text` would do, each risk once, in that order; none for plain text.
    /// - Complexity: O(the text's Unicode scalars).
    public static func of(_ text: String, bracketed: Bool) -> [Self] {
        var lines = 0
        var control = false
        var hidden = false
        var afterReturn = false
        for scalar in text.unicodeScalars {
            let value = scalar.value
            switch value {
                case 0x0D:
                    lines += 1
                case 0x0A:
                    if !afterReturn { lines += 1 }
                case 0x09:
                    break
                case 0x00 ... 0x1F, 0x7F, 0x80 ... 0x9F:
                    control = true
                default:
                    if isHidden(value) { hidden = true }
            }
            afterReturn = value == 0x0D
        }
        var risks: [Self] = []
        if !bracketed, lines > 0 { risks.append(.runs(lines: lines)) }
        if control { risks.append(.controlCharacters) }
        if hidden { risks.append(.hiddenCharacters) }
        return risks
    }

    private static func isHidden(_ value: UInt32) -> Bool {
        switch value {
            case 0x00AD, 0x061C, 0x180E, 0x200B ... 0x200F, 0x202A ... 0x202E, 0x2060 ... 0x2064, 0x2066 ... 0x2069,
                0xFEFF,
                0xE0000 ... 0xE007F:
                true
            default:
                false
        }
    }
}
