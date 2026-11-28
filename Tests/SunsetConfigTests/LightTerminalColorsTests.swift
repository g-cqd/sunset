import Foundation
import Testing

@testable import SunsetConfig

/// The terminal's light colours (design 0009): dark text on a near-white screen in light unless the file says otherwise;
/// a colour chosen is the same in both schemes; the palette has light values like any setting.
@Suite("The terminal's light colours")
struct LightTerminalColorsTests {
    /// WCAG's contrast ratio of two colours.
    private static func contrast(_ first: [UInt8], _ second: [UInt8]) -> Double {
        func luminance(_ colour: [UInt8]) -> Double {
            let linear = colour.map { byte -> Double in
                let value = Double(byte) / 255
                return value <= 0.039_28 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
        }
        let (light, dark) = (max(luminance(first), luminance(second)), min(luminance(first), luminance(second)))
        return (light + 0.05) / (dark + 0.05)
    }

    @Test func `by default the terminal has macOS's colours in each scheme, readable on its screen`() throws {
        let light = Configuration().inLight().colors
        #expect(light.background == Configuration.Colors.lightBackground)
        #expect(
            light.foreground == Configuration.Colors.lightForeground && light.ansi == Configuration.Colors.lightAnsi
        )
        let dark = Configuration().colors
        #expect(dark.background == [0x1E, 0x1E, 0x1E] && dark.foreground == [0xDD, 0xDD, 0xDD])
        #expect(Self.contrast(try #require(dark.foreground), try #require(dark.background)) >= 7)
        let screen = try #require(light.background)
        #expect(Self.contrast(try #require(light.foreground), screen) >= 7)
        for (index, colour) in light.ansi.enumerated() where index != 15 {
            #expect(Self.contrast(colour, screen) >= (index < 8 ? 4.5 : 3), "colour \(index)")
        }
    }

    @Test func `a file that says nothing keeps macOS's; a colour in a file of before is both schemes'`() throws {
        let written = ConfigurationWriter.text(for: Configuration())
        #expect(try ConfigurationParser.parse(written).configuration == Configuration())
        let chosen = try ConfigurationParser.parse(##"{ "colors": { "background": "#202830" } }"##).configuration
        #expect(chosen.inLight().colors.background == [0x20, 0x28, 0x30])
        #expect(chosen.inLight().colors.ansi == Configuration.Colors.lightAnsi, "the rest keep macOS's light")
    }

    @Test func `the palette changed in dark keeps its light one; a pair is read and written back`() throws {
        var configuration = Configuration()
        configuration.colors.ansi[1] = [0xFF, 0x00, 0x00]
        let dark = try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration)).configuration
        #expect(dark == configuration && dark.inLight().colors.ansi[1] == Configuration.Colors.lightAnsi[1])
        let pair = try ConfigurationParser.parse(
            ##"{ "colors": { "ansi": { "light": ["#000000", "#aa0000"], "dark": ["#111111", "#ff5555"] } } }"##
        )
        #expect(pair.issues.isEmpty)
        #expect(pair.configuration.colors.ansi[1] == [0xFF, 0x55, 0x55])
        #expect(pair.configuration.inLight().colors.ansi[1] == [0xAA, 0x00, 0x00])
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: pair.configuration)).configuration
        #expect(back == pair.configuration)
    }
}
