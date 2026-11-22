import Foundation

/// Reading the classes of a rule's value.
extension PasswordRules {
    /// The characters of a value: classes and bracketed characters, separated by commas.
    static func characters(_ value: String) -> Set<Character> {
        split(value, by: ",")
            .reduce(into: Set<Character>()) { all, item in
                let item = item.trimmingCharacters(in: .whitespaces)
                if item.hasPrefix("["), item.hasSuffix("]") {
                    all.formUnion(item.dropFirst().dropLast())
                    return
                }
                switch item.lowercased() {
                    case "lower": all.formUnion(CharacterClass.lower.characters)
                    case "upper": all.formUnion(CharacterClass.upper.characters)
                    case "digit": all.formUnion(CharacterClass.digit.characters)
                    case "special": all.formUnion("-~!@#$%^&*_+=`|(){}[:;\"'<>,.?] /")
                    case "ascii-printable":
                        all.formUnion((32 ... 126).compactMap { Unicode.Scalar($0).map(Character.init) })
                    default: break
                }
            }
    }

    /// `text` split at `separator`, but not inside brackets (`[-,;]` is one class).
    static func split(_ text: String, by separator: Character) -> [String] {
        var parts: [String] = []
        var current = ""
        var depth = 0
        for character in text {
            if character == "[" { depth += 1 }
            if character == "]" { depth = max(depth - 1, 0) }
            if character == separator, depth == 0 {
                parts.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        parts.append(current)
        return parts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}
