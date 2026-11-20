import Foundation
import Testing

@testable import SunsetShellModel
@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner, 2026-11-20 (task t135): the menus' less used items behind Option, as macOS's own menus have them ("Reload being
/// swapped to Force Reload when holding the Option key").
@MainActor @Suite("A page's tab menu: Force Reload behind Option")
struct MenuAlternatesTests {
    @Test func `Reload's Option alternate is Force Reload; no Force Reload item of its own`() throws {
        let page = WebContent(url: URL(string: "https://a.com"), settings: WebSettings(applicationName: "x"))
        let titles = page.menuActions.map(\.title)
        #expect(!titles.contains("Force Reload Page"), "\(titles)")
        let reload = try #require(page.menuActions.first { $0.title == "Reload Page" })
        #expect(reload.alternate?.title == "Force Reload Page")
    }
}
