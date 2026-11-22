import Foundation
import Testing

@testable import SunsetShell
@testable import SunsetShellModel
@testable import SunsetWeb
@testable import SunsetWebModel

/// A page's tab menu offers the website's settings.
@MainActor @Suite("What a page adds to its tab's menu")
struct PageMenuActionsTests {
    @Test func `a page with an address offers Reload, Copy Address and its site's settings; an empty page none`() {
        let page = WebContent(url: URL(string: "https://example.org/"), settings: WebSettings(applicationName: "x"))
        #expect(
            page.menuActions.map(\.title) == [
                "Reload Page", "Copy Address", "Site Settings\u{2026}"
            ]
        )
        let empty = WebContent(url: nil, settings: WebSettings(applicationName: "x"))
        #expect(empty.menuActions.isEmpty)
        page.menuActions.last?.run()
        #expect(page.showsSiteSettings)
    }
}
