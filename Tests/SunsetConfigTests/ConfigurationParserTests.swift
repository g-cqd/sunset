import Testing

@testable import SunsetConfig

@Suite("Configuration: reading a file") struct ConfigurationParserTests {
    private func read(_ text: String) throws(ConfigurationError) -> ConfigurationParser.Result {
        try ConfigurationParser.parse(text)
    }

    @Test func `an empty object is the defaults, with nothing to say`() throws {
        let result = try read("{}")
        #expect(result.configuration == Configuration())
        #expect(result.issues.isEmpty)
    }

    @Test func `comments and trailing commas are allowed, and every key is read`() throws {
        let result = try read(
            """
            // my terminal
            {
              "font": { "family": "JetBrains Mono", "size": 15.5, "ligatures": false, },
              "scrollback": { "lines": 50000 },
              "cursor": { "blinkTimeout": 30 }, /* seconds */
              "renderer": "cpu",
              "colors": { "foreground": "#e0e0e0", "background": "#101010", "cursor": "#ff8800" },
            }
            """
        )
        #expect(result.issues.isEmpty)
        let configuration = result.configuration
        #expect(configuration.font.family == "JetBrains Mono")
        #expect(configuration.font.size == 15.5)
        #expect(!configuration.font.ligatures)
        #expect(configuration.scrollbackLines == 50_000)
        #expect(configuration.cursorBlinkTimeout == 30)
        #expect(configuration.renderer == .cpu)
        #expect(configuration.colors.foreground == [0xE0, 0xE0, 0xE0])
        #expect(configuration.colors.background == [0x10, 0x10, 0x10])
        #expect(configuration.colors.cursor == [0xFF, 0x88, 0x00])
    }

    @Test func `a cursor timeout of null or 0 means the cursor blinks for ever`() throws {
        #expect(try read(#"{ "cursor": { "blinkTimeout": null } }"#).configuration.cursorBlinkTimeout == nil)
        #expect(try read(#"{ "cursor": { "blinkTimeout": 0 } }"#).configuration.cursorBlinkTimeout == nil)
    }

    @Test func `a value of the wrong type keeps the default and names the key`() throws {
        let result = try read(#"{ "font": { "size": "big" }, "scrollback": { "lines": true } }"#)
        #expect(result.configuration.font.size == 14)
        #expect(result.configuration.scrollbackLines == 10_000)
        #expect(result.issues.map(\.path).sorted() == ["font.size", "scrollback.lines"])
        #expect(result.issues.allSatisfy { !$0.message.isEmpty })
    }

    @Test func `a value out of range keeps the default and says what is allowed`() throws {
        let result = try read(#"{ "font": { "size": 3 }, "scrollback": { "lines": -5 } }"#)
        #expect(result.configuration.font.size == 14)
        #expect(result.configuration.scrollbackLines == 10_000)
        #expect(
            result.issues.contains { $0.path == "font.size" && $0.message.contains("4") && $0.message.contains("200") }
        )
        #expect(result.issues.contains { $0.path == "scrollback.lines" })
    }

    @Test func `an unknown key is reported and the rest is still read`() throws {
        let result = try read(#"{ "fnot": {}, "font": { "size": 16, "sise": 1 } }"#)
        #expect(result.configuration.font.size == 16)
        #expect(result.issues.map(\.path).sorted() == ["fnot", "font.sise"])
        #expect(result.issues.allSatisfy { $0.message.contains("unknown") })
    }

    @Test func `a renderer or a colour that is not one of the allowed forms is reported`() throws {
        let result = try read(##"{ "renderer": "metal", "colors": { "foreground": "red", "cursor": "#12345" } }"##)
        #expect(result.configuration.renderer == .auto)
        #expect(result.configuration.colors.foreground == nil && result.configuration.colors.cursor == nil)
        #expect(result.issues.map(\.path).sorted() == ["colors.cursor", "colors.foreground", "renderer"])
        #expect(result.issues.first { $0.path == "renderer" }?.message.contains("auto") == true)
    }

    @Test func `text that is not JSON is an error and says where`() {
        #expect(throws: ConfigurationError.self) { try read(#"{ "font": "#) }
        do {
            _ = try read("{ \"font\" 1 }")
            Issue.record("expected a syntax error")
        } catch {
            if case .syntax(let message, let offset) = error {
                #expect(!message.isEmpty)
                #expect(offset != nil)
            } else {
                Issue.record("wrong error \(error)")
            }
        }
    }

    @Test func `a document that is not an object is an error`() {
        #expect(throws: ConfigurationError.notAnObject) { try read("[1, 2]") }
        #expect(throws: ConfigurationError.notAnObject) { try read("3") }
    }

    @Test func `the window section: decorations, where the traffic lights go, the height of the strip that drags`()
        throws
    {
        let result = try read(
            """
            { "window": { "decorations": "native", "trafficLights": { "x": 20, "y": 8.5 }, "dragStrip": 24 } }
            """
        )
        #expect(result.issues.isEmpty)
        #expect(result.configuration.window.decorations == .native)
        #expect(result.configuration.window.trafficLightsX == 20)
        #expect(result.configuration.window.trafficLightsY == 8.5)
        #expect(result.configuration.window.dragStrip == 24)
    }

    @Test func `the window defaults: no decorations, lights near the corner, a 16 pt strip`() throws {
        let window = try read("{}").configuration.window
        #expect(window.decorations == .none)
        #expect(window.trafficLightsX == 12 && window.trafficLightsY == 12)
        #expect(window.dragStrip == 16)
    }

    @Test func `window values that are wrong are reported with their keys`() throws {
        let result = try read(
            """
            { "window": { "decorations": "fancy", "trafficLights": { "x": -4, "z": 1 }, "dragStrip": 500 } }
            """
        )
        #expect(
            result.issues.map(\.path).sorted() == [
                "window.decorations", "window.dragStrip", "window.trafficLights.x", "window.trafficLights.z"
            ]
        )
        #expect(result.configuration.window == Configuration.Window())
    }

    @Test func `the scroll section: trackpad and wheel sensitivity, with defaults of 1 and 3`() throws {
        let defaults = try read("{}").configuration.scroll
        #expect(defaults.trackpad == 1 && defaults.wheel == 3)
        let set = try read(#"{ "scroll": { "trackpad": 0.6, "wheel": 5 } }"#)
        #expect(set.issues.isEmpty)
        #expect(set.configuration.scroll.trackpad == 0.6 && set.configuration.scroll.wheel == 5)
    }

    @Test func `scroll values out of range or of the wrong kind are reported`() throws {
        let result = try read(#"{ "scroll": { "trackpad": 0, "wheel": "fast", "inertia": true } }"#)
        #expect(result.issues.map(\.path).sorted() == ["scroll.inertia", "scroll.trackpad", "scroll.wheel"])
        #expect(result.configuration.scroll == Configuration.Scroll())
    }
}
