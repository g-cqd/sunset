import Foundation
import Testing

@testable import SunsetCredentials

/// The generator (roadmap 0092 F): characters of the classes asked for, each present; a PIN; a page's `passwordrules`
/// shaping it, never shortening it below what the page itself allows (the research's policy). Drawn without modulo bias
/// from the generator given (the system's in the app, a seeded one here).
@Suite("The password generator")
struct PasswordGeneratorTests {
    /// A seeded generator (SplitMix64), so that a failure can be replayed.
    struct Seeded: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    @Test func `every class asked for is in every password, at the length asked`() {
        var random = Seeded(state: 1)
        let recipe = PasswordRecipe(length: 20, classes: [.lower, .upper, .digit, .symbol])
        for _ in 0 ..< 500 {
            let password = recipe.generate(using: &random)
            #expect(password.count == 20)
            for kind in CharacterClass.allCases {
                #expect(password.contains { kind.characters.contains($0) }, "\(kind) in \(password)")
            }
        }
    }

    @Test func `without the characters that look alike when asked; a PIN is digits`() {
        var random = Seeded(state: 2)
        let plain = PasswordRecipe(length: 32, classes: [.lower, .upper, .digit], avoidLookalikes: true)
        for _ in 0 ..< 200 {
            #expect(!plain.generate(using: &random).contains { "Il1O0o".contains($0) })
        }
        let pin = PasswordRecipe.pin(6).generate(using: &random)
        #expect(pin.count == 6 && pin.allSatisfy(\.isNumber))
    }

    @Test func `its strength in bits: length times the log of the alphabet`() {
        let recipe = PasswordRecipe(length: 16, classes: [.lower, .upper, .digit])
        #expect(abs(recipe.bits - 16 * log2(62)) < 0.001)
        #expect(abs(PasswordRecipe.pin(4).bits - 4 * log2(10)) < 0.001)
    }

    @Test func `a page's passwordrules: read, then kept to by every password`() throws {
        let rules = try #require(
            PasswordRules(
                "required: lower; required: upper; required: digit; allowed: [-().&@?'#,/\"+]; max-consecutive: 2; minlength: 12; maxlength: 18;"
            )
        )
        #expect(
            rules.required.count == 3 && rules.minLength == 12 && rules.maxLength == 18 && rules.maxConsecutive == 2
        )
        var random = Seeded(state: 3)
        let recipe = PasswordRecipe(length: 24, classes: [.lower, .upper, .digit, .symbol]).shaped(by: rules)
        #expect(recipe.length == 18, "the page allows no more than 18")
        for _ in 0 ..< 500 {
            let password = recipe.generate(using: &random)
            #expect((12 ... 18).contains(password.count))
            #expect(rules.allows(password), "\(password)")
        }
    }

    @Test func `a page cannot make it shorter than it allows, nor empty its alphabet`() throws {
        let short = try #require(PasswordRules("minlength: 4; maxlength: 64;"))
        #expect(PasswordRecipe(length: 20, classes: [.lower]).shaped(by: short).length == 20, "64 allowed: 20 stays")
        let digits = try #require(PasswordRules("allowed: digit; minlength: 30;"))
        let shaped = PasswordRecipe(length: 20, classes: [.lower, .upper]).shaped(by: digits)
        #expect(shaped.length == 30 && shaped.alphabet.allSatisfy(\.isNumber))
        #expect(PasswordRules("nonsense") == nil || PasswordRules("nonsense")?.isEmpty == true)
    }
}
