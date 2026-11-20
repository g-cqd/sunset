import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// The owner's notes n64 and n65 ("opening a image in another window does not work", "popup dont work"): what a page opens
/// itself (a link with a target, `window.open` after a click, WebKit's Open Image or Video in New Window) went to a tab after
/// it that was not shown. The owner, 2026-11-20: shown, as Safari does, with a setting; Sunset's own menu items keep theirs.
@Suite("Where a page a page opens goes")
struct OpenedPagePlacementTests {
    @Test func `what the page asks for is an opened page; a sized pop-up a window; Sunset's own item wins`() {
        #expect(WebCoordinator.placement(chosen: nil, sized: false) == .opened)
        #expect(WebCoordinator.placement(chosen: nil, sized: true) == .window)
        #expect(WebCoordinator.placement(chosen: .tabAfter, sized: false) == .tabAfter, "Open Link in New Tab: behind")
        #expect(WebCoordinator.placement(chosen: .splitRight, sized: true) == .splitRight)
    }
}
