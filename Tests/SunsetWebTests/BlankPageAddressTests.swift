import Testing

@testable import SunsetWeb

/// n52: an empty page told the bar takes its address no longer asks for it itself.
@MainActor @Suite("An empty page and the command bar")
struct BlankPageAddressTests {
    @Test func `leaving the address to the bar takes back the page's own call for it`() {
        let page = WebContent(url: nil, settings: WebSettings())
        page.wantsAddress = true
        page.leaveAddressToBar()
        #expect(!page.wantsAddress)
    }
}
