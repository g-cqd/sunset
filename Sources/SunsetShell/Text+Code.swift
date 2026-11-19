package import SwiftUI

/// An address, a host, a URL, a path, a command or a keyword (the owner's note n26): in the system's monospaced design, at
/// the size and weight it has otherwise, so that it reads as what is typed.
extension Text {
    package func code() -> Text {
        fontDesign(.monospaced)
    }
}

extension Text {
    /// `sentence` with each of `parts` in it (a host, an address) as code: "`example.com` wants to use your camera."
    package static func sentence(_ sentence: String, code parts: [String]) -> Text {
        Text(codeSpans(sentence, parts))
    }

    /// The same as an attributed string: each part marked as code (`inlinePresentationIntent`), every time it is there.
    package static func codeSpans(_ sentence: String, _ parts: [String]) -> AttributedString {
        var text = AttributedString(sentence)
        for part in parts where !part.isEmpty {
            var from = text.startIndex
            while let found = text[from...].range(of: part) {
                text[found].inlinePresentationIntent = .code
                from = found.upperBound
            }
        }
        return text
    }
}
