import Testing

@testable import SunsetConfig

/// Keys taken out of a file as a person wrote it (n115): the member and its comma, its lines when they are its own; the
/// rest kept as written, comments and trailing commas included.
@Suite("Configuration file: removing keys") struct ConfigurationRemovingTests {
    @Test func `a member, a whole section, the rest kept as written`() throws {
        let text = """
            {
              // The window.
              "window": {
                "decorations": "none",
                "trafficLights": {
                  "x": 8,
                  "y": 8,
                  "side": "sidebar",
                },
                "dragStrip": 16, // the strip
                "padding": 4,
              },
              "font": { "size": 13 }
            }
            """
        let out = try #require(
            ConfigurationPatcher.removing(text, paths: ["window.decorations", "window.trafficLights", "window.absent"])
        )
        #expect(
            out == """
                {
                  // The window.
                  "window": {
                    "dragStrip": 16, // the strip
                    "padding": 4,
                  },
                  "font": { "size": 13 }
                }
                """
        )
        let parsed = try ConfigurationParser.parse(out)
        #expect(parsed.configuration.window.dragStrip == 16 && parsed.configuration.font.size == 13)
    }

    @Test func `the last member takes the comma before it; one inline keeps its line`() throws {
        let text = #"{ "window": { "dragStrip": 16, "decorations": "none" }, "font": { "size": 13 } }"#
        let out = try #require(ConfigurationPatcher.removing(text, paths: ["window.decorations"]))
        #expect(out == #"{ "window": { "dragStrip": 16 }, "font": { "size": 13 } }"#)
        #expect(ConfigurationPatcher.removing("[1]", paths: ["a"]) == nil)
    }

    @Test func `the keys made fixed are read without a word and go when the file is saved`() throws {
        let text = """
            {
              "window": { "decorations": "native", "trafficLights": { "x": 30 }, "dragStrip": 16 },
              "sidebar": { "side": "right" }
            }
            """
        let read = try ConfigurationParser.parse(text)
        #expect(read.issues.isEmpty)
        #expect(
            read.configuration.window.decorations == .none && read.configuration.window.trafficLightsX == 8,
            "fixed"
        )
        var changed = read.configuration
        changed.window.dragStrip = 20
        let saved = try #require(ConfigurationPatcher.saved(changed, over: text))
        #expect(!saved.contains("decorations") && !saved.contains("trafficLights") && saved.contains("20"))
        #expect(saved.contains(#""side": "right""#))
    }
}
