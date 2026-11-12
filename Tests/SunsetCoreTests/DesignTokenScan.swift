import Foundation

/// Finds measures written as numbers in views (design 0003 §8): a literal other than 0 inside a padding, a stack's spacing, a corner radius,
/// an opacity (1 allowed there: on or off), a shadow or a fixed font size. Comments are not read; the token files are not scanned.
enum DesignTokenScan {
    static let folders = ["Sources/SunsetShell", "Sources/SunsetWeb", "Sources/SunsetApp"]
    static let tokenFiles: Set<String> = ["Design.swift", "Design+Look.swift"]

    /// What opens a measured argument, and the literals allowed in it.
    private static let openers: [(String, Set<String>)] = [
        (".padding(", ["0"]), ("spacing: ", ["0"]), ("cornerRadius: ", ["0"]), (".opacity(", ["0", "1"]),
        (".shadow(", ["0"]), (".font(.system(size: ", ["0"])
    ]

    /// The places in a file's text, as "line: text".
    static func findings(in text: String) -> [String] {
        var found: [String] = []
        for (number, raw) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = String(raw.split(separator: "//", maxSplits: 1, omittingEmptySubsequences: false).first ?? "")
            for (opener, allowed) in openers {
                var rest = line[...]
                while let range = rest.range(of: opener) {
                    let argument = argumentText(rest[range.upperBound...], opener: opener)
                    if literals(in: argument).contains(where: { !allowed.contains($0) }) {
                        let place = "\(number + 1): \(line.trimmingCharacters(in: .whitespaces))"
                        if found.last != place { found.append(place) }
                    }
                    rest = rest[range.upperBound...]
                }
            }
        }
        return found
    }

    /// The argument: up to the closing parenthesis of the call (or, for a labelled argument, up to the next comma or parenthesis).
    private static func argumentText(_ text: Substring, opener: String) -> Substring {
        let labelled = opener.hasSuffix(": ") && !opener.contains("(")
        var depth = opener.hasSuffix("(") || opener.hasSuffix(": ") && opener.contains("(") ? 1 : 0
        var end = text.startIndex
        for index in text.indices {
            let character = text[index]
            if character == "(" { depth += 1 }
            if character == ")" { depth -= 1 }
            if depth < 0 || labelled && depth == 0 && character == "," || !labelled && depth == 0 { break }
            end = text.index(after: index)
        }
        return text[text.startIndex ..< end]
    }

    /// The numeric literals in a piece of code (not inside a name: `x2` is not one).
    static func literals(in code: Substring) -> [String] {
        var found: [String] = []
        var current = ""
        var previous: Character = " "
        for character in code + " " {
            if character.isNumber || character == "." && !current.isEmpty {
                if current.isEmpty, previous.isLetter || previous == "_" || previous == "." {
                    previous = character
                    continue
                }
                current.append(character)
            } else {
                if !current.isEmpty { found.append(normalised(current)) }
                current = ""
            }
            previous = character
        }
        return found
    }

    private static func normalised(_ literal: String) -> String {
        guard let value = Double(literal.trimmingCharacters(in: CharacterSet(charactersIn: "."))) else {
            return literal
        }
        return value == value.rounded() ? String(Int(value)) : String(value)
    }

    /// Every scanned file with findings, by name.
    static func repository() -> [String: [String]] {
        var result: [String: [String]] = [:]
        for file in RepositoryFiles.swiftFiles(in: folders) where !tokenFiles.contains(file.name) {
            let found = findings(in: file.text)
            if !found.isEmpty { result[file.name] = found }
        }
        return result
    }
}
