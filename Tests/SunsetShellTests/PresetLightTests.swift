import SunsetPane
import Testing

@testable import SunsetShell

/// The fourth light (n78, t287): the selected tab laid out by a preset, the tabs after it joining; its colour the system's
/// accent, blue when the accent is near a light's own colour (red, yellow, green) or has none (graphite).
@MainActor
@Suite("The fourth light")
struct PresetLightTests {
    @Test func `a preset lays the selected tab out, the next tabs joining it`() throws {
        let harness = TabsHarness()
        let tabs = harness.tabs
        tabs.newTab()
        tabs.newTab()
        tabs.newTab()
        tabs.select(index: 0)
        let first = try #require(tabs.workspace.selectedItem)
        #expect(tabs.canApply(.threeColumns) && !tabs.canApply(.grid))
        tabs.apply(.threeColumns)
        #expect(tabs.workspace.items.count == 1 && tabs.workspace.items[0].panes.count == 3)
        #expect(tabs.workspace.selectedID == first.id)
    }

    @Test func `its colour is the accent, unless it is near a light's colour or has none`() {
        #expect(PresetLightColor.usesAccent(hue: 0.6, saturation: 0.8))  // blue
        #expect(PresetLightColor.usesAccent(hue: 0.8, saturation: 0.6))  // purple
        #expect(PresetLightColor.usesAccent(hue: 0.92, saturation: 0.6))  // pink
        #expect(!PresetLightColor.usesAccent(hue: 0.0, saturation: 0.8))  // red
        #expect(!PresetLightColor.usesAccent(hue: 0.08, saturation: 0.9))  // orange, the yellow light's amber
        #expect(!PresetLightColor.usesAccent(hue: 0.14, saturation: 0.9))  // yellow
        #expect(!PresetLightColor.usesAccent(hue: 0.33, saturation: 0.7))  // green
        #expect(!PresetLightColor.usesAccent(hue: 0.6, saturation: 0.05))  // graphite
    }
}
