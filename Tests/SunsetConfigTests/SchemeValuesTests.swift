import Testing

@testable import SunsetConfig

/// The look settings have a value in light and one in dark, each macOS's until changed in that scheme (design 0009):
/// `{ "light": …, "dark": … }` in the file, either left out, `{}` for macOS's in both, one value for both.
@Suite("Light and dark values")
struct SchemeValuesTests {
    @Test func `macOS's in both until changed; one value is both schemes'; a pair each its own; read back the same`()
        throws
    {
        let none = try ConfigurationParser.parse("{}").configuration
        #expect(!none.changes("colors.background", light: true) && !none.changes("colors.background", light: false))
        #expect(none.inLight().colors.background == Configuration.Colors.lightBackground)
        let one = try ConfigurationParser.parse(##"{ "colors": { "background": "#101010" } }"##).configuration
        #expect(one.colors.background == [0x10, 0x10, 0x10] && one.inLight().colors.background == [0x10, 0x10, 0x10])
        let pair = try ConfigurationParser.parse(
            ##"{ "colors": { "background": { "light": "#fafafa", "dark": "#101010" } } }"##
        )
        #expect(pair.issues.isEmpty)
        #expect(pair.configuration.colors.background == [0x10, 0x10, 0x10])
        #expect(pair.configuration.inLight().colors.background == [0xFA, 0xFA, 0xFA])
        for configuration in [none, one, pair.configuration] {
            let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
            #expect(back.configuration == configuration && back.issues.isEmpty)
        }
    }

    @Test func `changed in one scheme only, the other keeps macOS's; reset puts it back`() throws {
        let light = try ConfigurationParser.parse(
            ##"{ "appearance": { "tint": { "color": { "light": "#ff0000" } } } }"##
        )
        #expect(light.issues.isEmpty)
        var configuration = light.configuration
        #expect(
            configuration.appearance.tintColor == nil && configuration.inLight().appearance.tintColor == [255, 0, 0]
        )
        #expect(ConfigurationWriter.scheme("appearance.tint.color", configuration) == ##"{ "light": "#ff0000" }"##)
        configuration.resetToNative("appearance.tint.color", light: true)
        #expect(configuration.inLight().appearance.tintColor == nil)
        #expect(ConfigurationWriter.scheme("appearance.tint.color", configuration) == "{}")
        configuration.appearance.tintColor = [0, 0, 255]
        #expect(configuration.changes("appearance.tint.color", light: false))
        configuration.resetToNative("appearance.tint.color", light: false)
        #expect(configuration == Configuration())
    }

    @Test func `a light value that is not one is said, and the dark one kept; other settings read a pair's dark`()
        throws
    {
        let read = try ConfigurationParser.parse(
            ##"{ "colors": { "background": { "light": "pink", "dark": "#101010" } } }"##
        )
        #expect(read.issues.map(\.path) == ["terminal.colors.background"])
        #expect(read.configuration.colors.background == [0x10, 0x10, 0x10])
        #expect(!read.configuration.changes("colors.background", light: true))
        let bars = try ConfigurationParser.parse(
            #"{ "appearance": { "barTint": { "light": "light", "dark": "dark" } } }"#
        )
        #expect(bars.configuration.appearance.barTint == .dark && bars.issues.isEmpty, "bars are shared now")
    }

    @Test func `an opaque or filled window is a colour: opaque has no tint; the file is to be written again`() throws {
        let opaque = try ConfigurationParser.parse(
            ##"{ "window": { "material": "opaque" }, "appearance": { "tint": { "color": "#3060ff", "alpha": 0.3 } } }"##
        )
        #expect(opaque.hasFormerValues && opaque.issues.isEmpty)
        for scheme in [opaque.configuration, opaque.configuration.inLight()] {
            #expect(scheme.window.material == .color && scheme.appearance.tintColor == nil)
        }
        let fill = try ConfigurationParser.parse(
            ##"{ "window": { "material": "fill" }, "appearance": { "tint": { "color": "#3060ff" } } }"##
        )
        #expect(
            fill.configuration.window.material == .color && fill.configuration.appearance.tintColor == [48, 96, 255]
        )
        let former = ##"{ "window": { "material": "opaque" } }"##
        let upgraded = try #require(ConfigurationPatcher.upgraded(former))
        let again = try ConfigurationParser.parse(upgraded)
        let read = try ConfigurationParser.parse(former).configuration
        #expect(!again.hasFormerValues && again.configuration == read)
    }
}
