import Foundation
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner's note n18 (2026-11-18): "sunset still does not act as a browser for macos and cannot be set as default browser".
/// What the system hands Sunset to open: links to pages, and files.
@Suite("What another app asks Sunset to open")
struct IncomingLinksTests {
    @Test func `web links are pages; files are files; anything else is neither`() throws {
        let urls = try [
            #require(URL(string: "https://example.org/a?b=1")),
            #require(URL(string: "http://example.org/")),
            URL(fileURLWithPath: "/tmp/notes.md"),
            #require(URL(string: "mailto:someone@example.org")),
            #require(URL(string: "javascript:alert(1)"))
        ]
        let split = IncomingLinks.split(urls)
        #expect(split.pages.map(\.absoluteString) == ["https://example.org/a?b=1", "http://example.org/"])
        #expect(split.files == ["/tmp/notes.md"])
    }

    /// The owner's note n66: a link from another app opens in a peek window, a pop-up's kind with back, forward and an address
    /// field; the person moves it to a Space. Off, a tab; with the web off, the system's browser.
    @Test func `a link from another app goes to a peek window, a tab, or the system's browser`() {
        #expect(IncomingLinks.place(peek: true, webOn: true) == .peek)
        #expect(IncomingLinks.place(peek: false, webOn: true) == .tab)
        #expect(IncomingLinks.place(peek: true, webOn: false) == .systemBrowser)
    }

    /// Only the peek window navigates (n66: "this should only be possible for the peek windows, not the popup ones").
    @Test func `a peek window has back, forward and an address field; a pop-up has none`() {
        #expect(DetachedWindowKind.peek.navigates)
        #expect(!DetachedWindowKind.popup.navigates)
    }

    /// Seen 2026-11-20 (task t132): a private page's pop-up offered every Space and went to the window in front. A private
    /// page goes only to a private window; the Spaces' menu is not offered.
    @Test func `a private page's pop-up goes only to a private window; it is offered no Space`() {
        #expect(DetachedWindowKind.offersSpaces(private: false))
        #expect(!DetachedWindowKind.offersSpaces(private: true))
        #expect(DetachedWindowKind.fits(window: .init(isPrivate: true), private: true))
        #expect(!DetachedWindowKind.fits(window: .init(isPrivate: false), private: true))
        #expect(
            !DetachedWindowKind.fits(window: .init(isPrivate: true), private: false),
            "nor a normal page a private window"
        )
        #expect(DetachedWindowKind.fits(window: .init(isPrivate: false), private: false))
    }
}
