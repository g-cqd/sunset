import Foundation

/// How a password is made (roadmap 0092 F): its length; groups of characters it has at least one of each; the alphabet the
/// rest is drawn from; how many identical characters may follow each other. Drawn without modulo bias (`Int.random(in:
/// using:)`) from the generator given: the system's in the app.
public struct PasswordRecipe: Sendable, Equatable {
    public var length: Int
    public var required: [[Character]]
    public var alphabet: [Character]
    public var maxConsecutive: Int?

    public init(length: Int, classes: [CharacterClass], avoidLookalikes: Bool = false) {
        let groups = classes.map { kind in
            Array(kind.characters).filter { !avoidLookalikes || !CharacterClass.lookalikes.contains($0) }
        }
        self.length = length
        self.required = groups.filter { !$0.isEmpty }
        self.alphabet = groups.flatMap(\.self)
    }

    public static func pin(_ digits: Int) -> Self {
        PasswordRecipe(length: digits, classes: [.digit])
    }

    /// Its strength, as a password drawn uniformly from its alphabet: length × log₂(alphabet).
    public var bits: Double {
        Double(length) * log2(Double(max(Set(alphabet).count, 1)))
    }

    /// A password: one character of each required group, the rest from the alphabet, in an order drawn too; drawn again
    /// while it has a run longer than allowed.
    public func generate(using random: inout some RandomNumberGenerator) -> String {
        guard !alphabet.isEmpty, length > 0 else { return "" }
        while true {
            var characters = required.prefix(length).compactMap { $0.randomElement(using: &random) }
            while characters.count < length {
                characters.append(alphabet[Int.random(in: 0 ..< alphabet.count, using: &random)])
            }
            characters.shuffle(using: &random)
            let password = String(characters)
            if maxConsecutive.map({ PasswordRules.longestRun(password) <= $0 }) ?? true { return password }
        }
    }

    /// Shaped by a page's rules: its alphabet and required groups when it names any, its maximum length when it is
    /// shorter, its minimum when it is longer; never made shorter than it allows, nor given an empty alphabet.
    public func shaped(by rules: PasswordRules) -> Self {
        var shaped = self
        if let allowed = rules.alphabet, !allowed.isEmpty {
            shaped.alphabet = allowed.sorted()
            let required = rules.required.map { $0.sorted() }.filter { !$0.isEmpty }
            shaped.required =
                required.isEmpty ? self.required.map { $0.filter(allowed.contains) }.filter { !$0.isEmpty } : required
        }
        shaped.length = max(length, rules.minLength ?? 0)
        if let longest = rules.maxLength { shaped.length = min(shaped.length, longest) }
        shaped.maxConsecutive = rules.maxConsecutive ?? maxConsecutive
        return shaped
    }
}
