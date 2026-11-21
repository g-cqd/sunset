import SunsetConfig
import Testing

@testable import SunsetAppCore

/// The owner's notes n69–n71: what Command-T makes, from `tabs.newTab` and the focused tab.
@Suite("What Command-T makes")
struct NewTabKindTests {
    @Test func `following the focused tab: a page makes a page, a private one a private one, a document a document`() {
        #expect(NewTabKind.resolve(.focused, focused: .page(isPrivate: false)) == .page(isPrivate: false))
        #expect(NewTabKind.resolve(.focused, focused: .page(isPrivate: true)) == .page(isPrivate: true))
        #expect(NewTabKind.resolve(.focused, focused: .document) == .document)
        #expect(NewTabKind.resolve(.focused, focused: .terminal) == .terminal)
        #expect(NewTabKind.resolve(.focused, focused: .other) == .terminal)
        #expect(NewTabKind.resolve(.focused, focused: nil) == .terminal)
    }

    @Test func `set to one kind: that kind, a page private only in a private page`() {
        #expect(NewTabKind.resolve(.terminal, focused: .page(isPrivate: false)) == .terminal)
        #expect(NewTabKind.resolve(.document, focused: .terminal) == .document)
        #expect(NewTabKind.resolve(.web, focused: .terminal) == .page(isPrivate: false))
        #expect(NewTabKind.resolve(.web, focused: .page(isPrivate: true)) == .page(isPrivate: true))
    }
}
