import Testing

@testable import SunsetConfig

/// The owner's note n29 (2026-11-18): "the glass type should only be shown when the glass is set for the window, and same goes
/// for the material kind when it is set to material". What a choice only changes under another is shown under it only.
@Suite("Settings shown only where they act") struct SettingsShownWhenTests {
    private func shown(_ id: String, _ material: Configuration.Material) -> Bool {
        var configuration = Configuration()
        configuration.window.material = material
        return SettingsOption.named(id)?.isShown(in: configuration) == true
    }

    @Test
    func
        `the glass style with glass, the thickness with a material, the blur with either, the opacity with any but opaque`()
    {
        #expect(Configuration.Material.allCases.filter { shown("appearance.glass", $0) } == [.glass])
        #expect(Configuration.Material.allCases.filter { shown("window.materialThickness", $0) } == [.material])
        #expect(Configuration.Material.allCases.filter { shown("window.blur", $0) } == [.material, .glass])
        #expect(Configuration.Material.allCases.filter { shown("terminal.opacity", $0) } == [.material, .glass, .fill])
        #expect(shown("window.material", .opaque), "an option with no condition is always shown")
    }
}
