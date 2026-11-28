import Testing

@testable import SunsetConfig

/// With the window background "Material", a choice from ultrathin to ultrathick.
@Suite("The material's thickness")
struct MaterialThicknessTests {
    @Test func `read, written, regular by default, and offered beside the background`() throws {
        #expect(Configuration().window.materialThickness == .regular)
        let read = try ConfigurationParser.parse(#"{ "window": { "materialThickness": "ultraThick" } }"#).configuration
        #expect(read.window.materialThickness == .ultraThick)
        var written = Configuration()
        written.window.materialThickness = .ultraThin
        #expect(ConfigurationWriter.text(for: written).contains(#""materialThickness": { "dark": "ultraThin" }"#))
        #expect(
            SettingsOption.named("window.materialThickness")?.topic == SettingsOption.named("window.material")?.topic
        )
        #expect(Configuration.MaterialThickness.allCases.count == 5)
    }
}
