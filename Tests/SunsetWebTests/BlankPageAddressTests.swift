import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner's note n52, its cause: an empty page asked for its address whenever its view was made (a restored empty tab,
/// Reload As, the first show), so the window's bar came out beside the command bar that the new tab had opened. Asking is
/// the action's that makes a new page (the command bar for a new tab), not the view's.
@MainActor @Suite("An empty page's address")
struct BlankPageAddressTests {
    @Test func `an empty page's view, made, asks for nothing by itself`() {
        let page = WebContent(url: nil, settings: WebSettings())
        page.makeLoadedForSharing()
        #expect(page.webView != nil && !page.wantsAddress)
    }
}
