import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// What a page opens itself (a link with a target, `window.open` after a click, WebKit's Open Image or Video in New Window)
/// went to a tab after it that was not shown. The owner, 2026-11-20: shown, as Safari does, with a setting; Sunset's own menu
/// items keep theirs.
@Suite("Where a page a page opens goes")
struct OpenedPagePlacementTests {
    @Test func `what the page asks for is an opened page; Sunset's own item wins`() {
        let rule = PopupWindows.never
        #expect(WebCoordinator.placement(chosen: nil, sized: false, fromLink: false, popups: rule) == .opened)
        #expect(WebCoordinator.placement(chosen: .tabAfter, sized: false, fromLink: true, popups: rule) == .tabAfter)
        #expect(
            WebCoordinator.placement(chosen: .splitRight, sized: true, fromLink: false, popups: .sized) == .splitRight
        )
    }

    /// A pop-up the page sized opens in a pop-up window, not a tab and not a window of tabs; a link with a target stays
    /// a tab ("we should respect target blank though, those should be tabs"); a setting says which pop-ups: those the
    /// page sized (the default), every one a script opens, or none.
    @Test func `pop-ups go to a pop-up window as web.popupWindows says; a link with a target stays a tab`() {
        func place(_ rule: PopupWindows, sized: Bool, link: Bool, chosen: WebPlacement? = nil) -> WebPlacement {
            WebCoordinator.placement(chosen: chosen, sized: sized, fromLink: link, popups: rule)
        }
        #expect(place(.sized, sized: true, link: false) == .popup)
        #expect(place(.sized, sized: false, link: false) == .opened)
        #expect(place(.sized, sized: true, link: true) == .opened, "a link with a target is a tab")
        #expect(place(.scripted, sized: false, link: false) == .popup)
        #expect(place(.scripted, sized: false, link: true) == .opened)
        #expect(place(.never, sized: true, link: false) == .opened)
        #expect(place(.sized, sized: true, link: false, chosen: .window) == .window, "Open Link in New Window")
    }
}
