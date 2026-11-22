import Foundation
import Testing

@testable import SunsetCredentials

/// A password made for a sign-up form (roadmap 0094 E): the page's own `passwordrules` first, else the rules Apple's
/// resources keep for the site, else none; then the generator's recipe shaped by them; always keeping to them.
@Suite("A new password for a page")
struct NewPasswordTests {
    @Test func `the page's rules first, the site's known rules else, none else`() {
        let page = "minlength: 12; maxlength: 16; required: digit;"
        let site = "required: upper; maxlength: 10;"
        #expect(NewPassword.rules(page: page, site: site)?.maxLength == 16)
        #expect(NewPassword.rules(page: "  ", site: site)?.maxLength == 10)
        #expect(NewPassword.rules(page: nil, site: nil) == nil)
        #expect(
            NewPassword.rules(page: "nonsense", site: site)?.maxLength == 10,
            "a page's rules that do not read: the site's"
        )
    }

    @Test func `made for the rules, and keeping to them`() throws {
        let rules = try #require(
            PasswordRules("minlength: 12; maxlength: 14; required: digit; required: upper; allowed: lower;")
        )
        for _ in 0 ..< 200 {
            let password = NewPassword.make(rules: rules)
            #expect(rules.allows(password), "\(password)")
        }
        #expect(NewPassword.make(rules: nil).count == NewPassword.recipe.length)
    }
}
