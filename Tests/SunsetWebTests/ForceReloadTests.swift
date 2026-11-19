import Foundation
import SunsetShell
import Testing

@testable import SunsetWeb

/// The owner's note n50: a tab stuck loading, or whose page process hangs or crashed, can be reloaded and force-reloaded.
/// Force: the page's process is ended and the page loads again in a new one, its history kept (probed: `/tmp/killprobe`).
@MainActor @Suite("Reload and force reload")
struct ForceReloadTests {
    @Test func `a page offers Reload and Force Reload in its tab's menu, loading or not`() {
        let page = WebContent(url: URL(string: "https://example.org/"), settings: WebSettings())
        let titles = page.menuActions.map(\.title)
        #expect(titles.contains("Reload Page") && titles.contains("Force Reload Page"))
    }

    @Test func `a force reload clears a crashed page's failure and makes its view again`() {
        let page = WebContent(url: URL(string: "https://example.org/"), settings: WebSettings())
        page.failure = .processEnded(url: page.url)
        page.forceReload()
        #expect(page.failure == nil && page.webView != nil)
    }
}
