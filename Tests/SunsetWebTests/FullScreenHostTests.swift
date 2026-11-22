import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// A video played full screen did not show. WebKit moves the page's view into its full-screen window; the host took it
/// back at its next layout (probed), leaving that window empty.
@MainActor @Suite("A page in full screen")
struct FullScreenHostTests {
    @Test func `the host takes the page's view back only while it is not in full screen`() {
        #expect(WebViewHostView.takesBack(.notInFullscreen))
        #expect(!WebViewHostView.takesBack(.enteringFullscreen))
        #expect(!WebViewHostView.takesBack(.inFullscreen))
        #expect(!WebViewHostView.takesBack(.exitingFullscreen))
    }
}
