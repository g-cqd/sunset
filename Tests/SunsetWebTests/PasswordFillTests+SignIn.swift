import Foundation
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

extension PasswordFillTests {
    /// A site a password is sent from keeps its data (`SignInWatch`); a submit the page dispatches itself is not one (the
    /// outside audit's MED-02: a page could keep its own cookies past the user's choice).
    @Test func `only a sign-in the person makes keeps the site's data`() async throws {
        let site = "signin-\(UUID().uuidString.prefix(8).lowercased()).example"
        let (_, view, _) = try await page(site: site)
        _ = try await view.callAsyncJavaScript(
            """
            document.getElementById('u').value = 'ada'; document.getElementById('p').value = 'forged';
            document.getElementById('f').dispatchEvent(new Event('submit', { bubbles: true }));
            document.getElementById('go').dispatchEvent(new MouseEvent('click', { bubbles: true }));
            """,
            contentWorld: .page
        )
        _ = try await view.callAsyncJavaScript("await new Promise(r => setTimeout(r, 200))", contentWorld: .page)
        #expect(!KeptSites.shared.keeps(site), "a made-up submit keeps nothing")
        try await signIn(in: view)
        await until { KeptSites.shared.keeps(site) }
        #expect(KeptSites.shared.keeps(site), "a real one keeps the site")
        KeptSites.shared.set(false, for: site)
    }
}
