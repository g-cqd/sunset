import Foundation
import SunsetConfig
import Testing

@testable import SunsetHost

@Suite("Tab presentation") struct TabPresentationTests {
    @Test func `each mode shows the tabs one way: windows, system tabs, the sidebar or the built-in bar`() {
        #expect(TabPresentation.resolve(mode: .none, sidebar: false) == .windows)
        #expect(
            TabPresentation.resolve(mode: .none, sidebar: true) == .windows,
            "no tabs, nothing for a sidebar to list"
        )
        #expect(TabPresentation.resolve(mode: .native, sidebar: false) == .nativeTabs)
        #expect(TabPresentation.resolve(mode: .native, sidebar: true) == .sidebar)
        #expect(TabPresentation.resolve(mode: .internal, sidebar: false) == .builtInBar)
        #expect(
            TabPresentation.resolve(mode: .internal, sidebar: true) == .builtInBar,
            "the built-in bar excludes native tabs and the sidebar"
        )
    }

    @Test func `what each presentation shows`() {
        #expect(!TabPresentation.windows.showsNativeTabBar && !TabPresentation.windows.showsSidebar)
        #expect(!TabPresentation.windows.showsBuiltInBar)
        #expect(TabPresentation.nativeTabs.showsNativeTabBar && !TabPresentation.nativeTabs.showsSidebar)
        #expect(!TabPresentation.sidebar.showsNativeTabBar && TabPresentation.sidebar.showsSidebar)
        #expect(TabPresentation.builtInBar.showsBuiltInBar && !TabPresentation.builtInBar.showsSidebar)
    }

    @Test func `where the tabs live: one window each with system tabs, all in one window with the sidebar or the bar`()
    {
        #expect(TabPresentation.nativeTabs.usesSystemTabbing)
        #expect(
            !TabPresentation.sidebar.usesSystemTabbing,
            "the system's bar cannot be hidden, so the sidebar does not sit on system tabs"
        )
        #expect(!TabPresentation.builtInBar.usesSystemTabbing && !TabPresentation.windows.usesSystemTabbing)
        #expect(TabPresentation.sidebar.hostsTabsInWindow && TabPresentation.builtInBar.hostsTabsInWindow)
        #expect(!TabPresentation.nativeTabs.hostsTabsInWindow && !TabPresentation.windows.hostsTabsInWindow)
    }
}
