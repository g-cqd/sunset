import Foundation
import Testing

@testable import SunsetSiteData

/// Task t118: Apple's password-manager-resources (MIT, read 2026-11-20), as roadmap 0094 will use them: a site's password
/// rules (for a generated password), the sites whose logins are offered on a site, and its change-password page. Looked up
/// from any host, up to its registrable domain.
@Suite("Password manager resources")
struct PasswordManagerResourcesTests {
    @Test func `a site's password rules, from any of its hosts`() throws {
        let resources = try PasswordManagerResources.bundled()
        #expect(resources.passwordRules(for: "163.com") == "minlength: 6; maxlength: 16;")
        #expect(resources.passwordRules(for: "www.163.com") == "minlength: 6; maxlength: 16;")
        #expect(resources.passwordRules(for: "example.org") == nil)
    }

    @Test func `logins offered on a site: a shared group all ways, a from-to one way only`() throws {
        let resources = try PasswordManagerResources.bundled()
        #expect(
            resources.loginSites(for: "www.envato.com")
                .isSuperset(of: ["envato.com", "audiojungle.net", "themeforest.net"])
        )
        #expect(resources.loginSites(for: "audiojungle.net").contains("envato.com"))
        #expect(
            resources.loginSites(for: "hosting.com").contains("a2hosting.com"),
            "a2hosting's logins move to hosting.com"
        )
        #expect(!resources.loginSites(for: "a2hosting.com").contains("hosting.com"), "not the other way")
        #expect(resources.loginSites(for: "example.org") == ["example.org"])
    }

    @Test func `a site's change-password page`() throws {
        let resources = try PasswordManagerResources.bundled()
        #expect(
            resources.changePasswordPage(for: "www.11st.co.kr")?.absoluteString
                == "https://www.11st.co.kr/register/popupModifyPWD.tmall"
        )
        #expect(resources.changePasswordPage(for: "example.org") == nil)
    }
}
