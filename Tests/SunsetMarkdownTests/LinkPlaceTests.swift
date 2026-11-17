import AppKit
import Testing

@testable import SunsetMarkdown

/// Where a click on a document's link opens it, by the keys held, as browsers document theirs (Safari's and Chrome's
/// help, read 2026-11-17): Command, a new tab behind; Command-Shift, a new tab shown; Shift, a new window. Sunset's own:
/// Option, beside the document. None: the setting.
@Suite("Where a document's link opens")
struct LinkPlaceTests {
    @Test func `the keys held choose, as in browsers; none, the setting`() {
        #expect(LinkPlace(modifiers: [], besideByDefault: false) == .tab)
        #expect(LinkPlace(modifiers: [], besideByDefault: true) == .beside)
        #expect(LinkPlace(modifiers: [.command], besideByDefault: true) == .backgroundTab)
        #expect(LinkPlace(modifiers: [.command, .shift], besideByDefault: true) == .tab)
        #expect(LinkPlace(modifiers: [.shift], besideByDefault: false) == .window)
        #expect(LinkPlace(modifiers: [.option], besideByDefault: false) == .beside)
        #expect(LinkPlace(modifiers: [.capsLock, .numericPad], besideByDefault: false) == .tab, "keys that say nothing")
    }
}
