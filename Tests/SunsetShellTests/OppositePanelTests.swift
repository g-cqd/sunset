import Foundation
import Testing

@testable import SunsetShell

/// The panel opposite the tabs, by its keys and menus.
@MainActor @Suite("The panel opposite the tabs") struct OppositePanelTests {
    @Test func `asking for a section shows the panel on it; asking again for the one shown hides it`() {
        let tabs = TabsModel()
        tabs.toggleOpposite(.history)
        #expect(tabs.showsHistory && tabs.sections.opposite == .history)
        tabs.toggleOpposite(.documents)
        #expect(tabs.showsHistory && tabs.sections.opposite == .documents, "another section: it stays, on that one")
        tabs.toggleOpposite(.documents)
        #expect(!tabs.showsHistory)
        tabs.toggleOpposite(.history, show: true)
        tabs.toggleOpposite(.history, show: true)
        #expect(tabs.showsHistory && tabs.sections.opposite == .history, "shown stays shown")
        tabs.toggleOpposite(.downloads, show: false)
        #expect(!tabs.showsHistory)
    }

    @Test func `the Library is offered by its setting: off, it is closed whatever it was on`() {
        let tabs = TabsModel()
        var settings = ShellSettings()
        tabs.sections.show(library: .history)
        #expect(tabs.librarySection(settings) == .history)
        settings.sidebar.library = false
        #expect(tabs.librarySection(settings) == nil)
        settings.sidebar.library = true
        tabs.sections.closeLibrary()
        #expect(tabs.librarySection(settings) == nil)
    }
}
