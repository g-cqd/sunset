import Foundation
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The settings in the window: a tab like any other, one in a window; the sidebar lists the sections and topics while
/// the Library is on its Settings section.
@MainActor @Suite("The settings as a tab") struct SettingsTabTests {
    let harness = TabsHarness()
    var tabs: TabsModel {
        harness.tabs
    }

    @Test func `asking for the settings opens their tab, and asking again shows the one that is there`() throws {
        tabs.newTab()
        let first = try #require(tabs.showSingle(.settings(topic: "general.startup")) as? FakeContent)
        #expect(tabs.workspace.count == 2 && tabs.workspace.selectedIndex == 1)
        #expect(
            first.descriptor.kind == PaneDescriptor.settingsKind && first.descriptor.state["topic"] == "general.startup"
        )
        tabs.select(index: 0)
        let again = tabs.showSingle(.settings(topic: "web.search"))
        #expect(again === first && tabs.workspace.count == 2 && tabs.workspace.selectedIndex == 1, "one in a window")
        #expect(tabs.single(kind: PaneDescriptor.settingsKind) === first && tabs.single(kind: "page") == nil)
    }

    @Test func `the settings beside another pane are found there, and take the keyboard`() throws {
        tabs.newTab()
        tabs.showSingle(.settings(topic: "general.startup"))
        tabs.newSplit(.right)
        let item = try #require(tabs.workspace.selectedItem)
        #expect(item.panes.count == 2 && tabs.document(in: item.focused) == nil)
        tabs.showSingle(.settings(topic: "general.startup"))
        #expect(tabs.workspace.count == 2)
        let focused = try #require(tabs.shownPane.flatMap(tabs.content))
        #expect(focused.descriptor.kind == PaneDescriptor.settingsKind)
    }

    @Test func `the gear shows the settings' list in the sidebar, whether or not the Library is offered`() {
        var settings = ShellSettings()
        tabs.sections.show(library: .settings)
        #expect(tabs.librarySection(settings) == .settings)
        settings.sidebar.library = false
        #expect(tabs.librarySection(settings) == .settings, "the settings are not the Library's to hide")
        tabs.sections.closeLibrary()
        #expect(tabs.librarySection(settings) == nil)
    }

    @Test func `the Library's glyph opens its lists, not the settings; the opposite panel never shows them`() {
        var sections = SidebarSections()
        sections.show(library: .history)
        sections.show(library: .settings)
        sections.closeLibrary()
        sections.toggleLibrary()
        #expect(sections.library == .history)
        sections.opposite = .settings
        #expect(sections.opposite == .history)
        #expect(!SidebarSection.rail.contains(.settings) && !SidebarSection.panel.contains(.settings))
    }

    @Test func `the page carries its own list unless the docked sidebar shows the settings' list`() {
        #expect(tabs.settingsListInPage(sidebarDocked: true))
        tabs.sections.show(library: .settings)
        #expect(!tabs.settingsListInPage(sidebarDocked: true))
        #expect(tabs.settingsListInPage(sidebarDocked: false), "a sidebar that hides, or none")
    }
}
