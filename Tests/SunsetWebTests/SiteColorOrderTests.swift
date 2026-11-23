import Foundation
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// A page's colour for its tab is its icon's, as the tab shows the icon (n118); its declared theme colour when the icon
/// has none that stands out.
@MainActor @Suite("A page's colour for its tab")
struct SiteColorOrderTests {
    @Test func `the icon's colour first, then the theme's`() {
        let page = WebContent(url: nil, settings: WebSettings(applicationName: "Version/26.0 Safari/605.1.15"))
        page.themeColor = [20, 90, 220]
        page.iconColor = [230, 40, 40]
        #expect(page.siteColor == [230, 40, 40])
        page.iconColor = [128, 128, 128]
        #expect(page.siteColor == [20, 90, 220], "a grey icon does not stand out")
        page.iconColor = nil
        page.themeColor = nil
        #expect(page.siteColor == nil)
    }
}
