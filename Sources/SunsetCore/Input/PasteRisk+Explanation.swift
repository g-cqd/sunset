/// What the paste warning says (task t116).
extension PasteRisk {
    /// The warning's title: the first risk's.
    public static func title(of risks: [Self]) -> String {
        switch risks.first {
            case .runs(let lines)?:
                lines == 1 ? "Paste text that runs a command?" : "Paste text that runs \(lines) commands?"
            case .controlCharacters?: "Paste text with control characters?"
            case .hiddenCharacters?, nil: "Paste text with hidden characters?"
        }
    }

    /// The risk in a sentence.
    public var sentence: String {
        switch self {
            case .runs(let lines):
                "The program has not asked for bracketed paste, so each of its \(lines) line ending\(lines == 1 ? "" : "s") "
                    + "is an Enter: the lines run as they land."
            case .controlCharacters:
                "It holds control characters (shown ␛, ␃…), which act on the program as the keys they stand for would."
            case .hiddenCharacters:
                "It holds characters that hide or reorder text (shown ⟨U+…⟩): what you see may not be what runs."
        }
    }

    /// The text as it would be sent, controls shown as their symbols and hidden characters by their code, cut after eight
    /// lines or 600 characters.
    public static func preview(_ text: String) -> String {
        var shown = ""
        var lines = 0
        var count = 0
        for scalar in text.unicodeScalars {
            if count >= 600 || lines >= 8 { return shown + "…" }
            switch scalar.value {
                case 0x0A:
                    lines += 1
                    shown += "\n"
                case 0x09, 0x0D:
                    shown.unicodeScalars.append(scalar)
                case 0x00 ... 0x1F:
                    shown.unicodeScalars.append(Unicode.Scalar(0x2400 + scalar.value) ?? "?")
                case 0x7F:
                    shown += "␡"
                case 0x80 ... 0x9F:
                    shown += "⟨U+00\(String(scalar.value, radix: 16, uppercase: true))⟩"
                default:
                    if of(String(scalar), bracketed: true) == [.hiddenCharacters] {
                        shown += "⟨U+\(String(scalar.value, radix: 16, uppercase: true))⟩"
                    } else {
                        shown.unicodeScalars.append(scalar)
                    }
            }
            count += 1
        }
        return shown
    }
}
