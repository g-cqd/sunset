import Testing

@testable import SunsetConfig

/// What a choice only changes under another is shown under it only.
@Suite("Settings shown only where they act") struct SettingsShownWhenTests {
    private func shown(_ id: String, _ material: Configuration.Material) -> Bool {
        var configuration = Configuration()
        configuration.window.material = material
        return SettingsOption.named(id)?.isShown(in: configuration) == true
    }

    @Test
    func
        `the glass style with glass, the thickness with a material, the blur and the opacity with any background`()
    {
        let all = Configuration.Material.allCases
        #expect(all.filter { shown("appearance.glass", $0) } == [.glass])
        #expect(all.filter { shown("window.materialThickness", $0) } == [.material])
        #expect(all.filter { shown("window.blur", $0) } == all)
        #expect(all.filter { shown("terminal.opacity", $0) } == all)
        #expect(shown("window.material", .color), "an option with no condition is always shown")
    }
}
