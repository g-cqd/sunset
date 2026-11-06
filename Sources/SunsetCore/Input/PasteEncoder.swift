/// Text pasted into the terminal, as the program should read it.
public enum PasteEncoder {
    /// With bracketed paste on the text is wrapped in `ESC [ 200 ~` ... `ESC [ 201 ~` so the program can tell it from typing, and the end marker is removed from
    /// the text (a paste must not be able to close its own brackets and have the rest read as typed commands). Without it, line feeds become carriage returns,
    /// as the Enter key sends.
    public static func encode(_ text: String, bracketed: Bool) -> [UInt8] {
        let bytes = Array(text.utf8)
        if bracketed {
            let marker = Array("\u{1B}[201~".utf8)
            // Removed until none is left: taking one out of "ESC [ 201 ESC [ 201 ~ ~" leaves another.
            var cleaned = bytes
            var changed = true
            while changed {
                changed = false
                var next: [UInt8] = []
                var index = 0
                while index < cleaned.count {
                    if index + marker.count <= cleaned.count, Array(cleaned[index ..< index + marker.count]) == marker {
                        index += marker.count
                        changed = true
                    } else {
                        next.append(cleaned[index])
                        index += 1
                    }
                }
                cleaned = next
            }
            return Array("\u{1B}[200~".utf8) + cleaned + marker
        }
        var result: [UInt8] = []
        var index = 0
        while index < bytes.count {
            if bytes[index] == 0x0D, index + 1 < bytes.count, bytes[index + 1] == 0x0A {
                result.append(0x0D)
                index += 2
            } else {
                result.append(bytes[index] == 0x0A ? 0x0D : bytes[index])
                index += 1
            }
        }
        return result
    }
}
