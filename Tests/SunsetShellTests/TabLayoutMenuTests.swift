import AppKit
import SunsetPane
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// A tab's menu lays tabs out: for several tabs selected, or a split tab; never for one plain tab.
@MainActor
@Suite("A tab's layouts")
struct TabLayoutMenuTests {
    @Test func `one plain tab offers no layout; several selected, or a split, do`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        for _ in 0 ..< 3 { tabs.newTab() }
        let ids = tabs.workspace.items.map(\.id)
        #expect(tabs.layoutTabs(for: .tab(ids[0])).isEmpty)
        tabs.marked = [.tab(ids[0]), .tab(ids[1])]
        #expect(tabs.layoutTabs(for: .tab(ids[1])) == [ids[0], ids[1]])
        tabs.apply(.sideBySide, to: [ids[0], ids[1]])
        #expect(tabs.workspace.items.count == tabs.workspace.count && tabs.marked.isEmpty)
        let split = try #require(tabs.workspace.items.first { $0.isSplit })
        #expect(tabs.layoutTabs(for: .tab(split.id)) == [split.id])
        #expect(tabs.workspace.presets(for: [split.id]) == [.sideBySide, .stacked])
    }

    @Test func `every layout has its picture`() {
        #expect(SplitPreset.allCases.allSatisfy { !PresetShape.image($0, dark: true).isTemplate })
        #expect(PresetShape.image(.grid, dark: true) !== PresetShape.image(.grid, dark: false))
    }
}
