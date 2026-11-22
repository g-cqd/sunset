import Foundation

/// A page's `passwordrules` attribute, as Apple's Password Manager Resources write it: `required:` and `allowed:` classes
/// (`lower`, `upper`, `digit`, `special`, `ascii-printable`, or characters in brackets), `minlength`, `maxlength`,
/// `max-consecutive`. Read only to shape a generated password (`PasswordRecipe.shaped(by:)`).
public struct PasswordRules: Sendable, Equatable {
    /// Groups a password has at least one character of each.
    public var required: [Set<Character>] = []
    /// What else it may hold.
    public var allowed: Set<Character> = []
    public var minLength: Int?
    public var maxLength: Int?
    public var maxConsecutive: Int?

    /// The rules of `text`; nil when it holds none that is understood.
    public init?(_ text: String) {
        for rule in Self.split(text, by: ";") {
            let parts = rule.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            let (name, value) = (parts[0].lowercased(), parts[1])
            switch name {
                case "required": required.append(Self.characters(value))
                case "allowed": allowed.formUnion(Self.characters(value))
                case "minlength": minLength = Int(value)
                case "maxlength": maxLength = Int(value)
                case "max-consecutive": maxConsecutive = Int(value)
                default: continue
            }
        }
        if isEmpty { return nil }
    }

    public var isEmpty: Bool {
        required.isEmpty && allowed.isEmpty && minLength == nil && maxLength == nil && maxConsecutive == nil
    }

    /// Every character it allows, when it names any.
    public var alphabet: Set<Character>? {
        let all = required.reduce(allowed) { $0.union($1) }
        return all.isEmpty ? nil : all
    }

    /// Whether `password` keeps to every rule.
    public func allows(_ password: String) -> Bool {
        (minLength.map { password.count >= $0 } ?? true) && (maxLength.map { password.count <= $0 } ?? true)
            && required.allSatisfy { group in password.contains(where: group.contains) }
            && (alphabet.map { all in password.allSatisfy(all.contains) } ?? true)
            && (maxConsecutive.map { Self.longestRun(password) <= $0 } ?? true)
    }

    /// The longest run of one character repeated.
    static func longestRun(_ text: String) -> Int {
        var (longest, run, last) = (0, 0, Character?.none)
        for character in text {
            run = character == last ? run + 1 : 1
            last = character
            longest = max(longest, run)
        }
        return longest
    }
}
