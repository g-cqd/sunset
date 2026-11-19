import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner's note n53: "playing a video full screen does not show the video at all". WebKit moves the page's view into its
/// full-screen window; the host took it back at its next layout (probed: `/tmp/fsprobe`), leaving that window empty.
@MainActor @Suite("A page in full screen")
struct FullScreenHostTests {
    @Test func `the host takes the page's view back only while it is not in full screen`() {
        #expect(WebViewHostView.takesBack(.notInFullscreen))
        #expect(!WebViewHostView.takesBack(.enteringFullscreen))
        #expect(!WebViewHostView.takesBack(.inFullscreen))
        #expect(!WebViewHostView.takesBack(.exitingFullscreen))
    }
}
