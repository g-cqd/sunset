/// A password made for a sign-up form (roadmap 0094 E): twenty characters of every class, shaped by the rules that apply
/// (the page's own `passwordrules`, else what Apple's resources keep for its site), drawn by the system's generator.
public enum NewPassword {
    /// What it is made of with no rule to keep to (the vault's own generator's recipe).
    public static let recipe = PasswordRecipe(length: 20, classes: CharacterClass.allCases)

    /// The rules that apply: the page's, when they read; else the site's; else none.
    public static func rules(page: String?, site: String?) -> PasswordRules? {
        if let page, let rules = PasswordRules(page) { return rules }
        return site.flatMap(PasswordRules.init)
    }

    public static func make(rules: PasswordRules?) -> String {
        var random = SystemRandomNumberGenerator()
        return (rules.map(recipe.shaped(by:)) ?? recipe).generate(using: &random)
    }
}
