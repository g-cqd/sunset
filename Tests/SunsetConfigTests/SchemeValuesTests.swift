import Testing

@testable import SunsetConfig

/// A plain setting can have a value of its own in light (design 0009): `{ "light": …, "dark": … }` in the file.
@Suite("Light and dark values")
struct SchemeValuesTests {
    @Test func `one value is both schemes'; a pair gives each its own, read back the same`() throws {
        let one = try ConfigurationParser.parse(##"{ "colors": { "background": "#101010" } }"##)
        #expect(one.configuration.lightValues.isEmpty && one.configuration.inLight() == one.configuration)
        let pair = try ConfigurationParser.parse(
            ##"{ "colors": { "background": { "light": "#fafafa", "dark": "#101010" } }, "appearance": { "barTint": { "light": "light", "dark": "dark" } } }"##
        )
        #expect(pair.issues.isEmpty)
        let configuration = pair.configuration
        #expect(configuration.colors.background == [0x10, 0x10, 0x10] && configuration.appearance.barTint == .dark)
        let light = configuration.inLight()
        #expect(light.colors.background == [0xFA, 0xFA, 0xFA] && light.appearance.barTint == .light)
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
        #expect(back.configuration == configuration)
    }

    @Test func `a light value that is not one is said, and the dark one kept`() throws {
        let read = try ConfigurationParser.parse(
            ##"{ "colors": { "background": { "light": "pink", "dark": "#101010" } } }"##
        )
        #expect(read.issues.map(\.path) == ["terminal.colors.background"])
        #expect(read.configuration.colors.background == [0x10, 0x10, 0x10] && read.configuration.lightValues.isEmpty)
    }
}
