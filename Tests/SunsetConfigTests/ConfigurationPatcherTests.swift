import Testing

@testable import SunsetConfig

@Suite("Configuration: patching a file in place") struct ConfigurationPatcherTests {
    private func patched(_ text: String, _ values: [String: String]) -> String? {
        ConfigurationPatcher.patch(text, set: values)
    }

    @Test func `a value is replaced and everything around it, comments included, is left alone`() throws {
        let text = """
            // my config
            {
              "font": {
                "size": 14, // points
                /* family next */ "family": "Menlo"
              },
            }
            """
        let result = try #require(patched(text, ["font.size": "18"]))
        #expect(
            result == """
                // my config
                {
                  "font": {
                    "size": 18, // points
                    /* family next */ "family": "Menlo"
                  },
                }
                """
        )
    }

    @Test func `a key that is missing is added to its section, in the style of the file`() throws {
        let text = "{\n  \"font\": {\n    \"size\": 14\n  }\n}\n"
        let result = try #require(patched(text, ["font.family": "\"Menlo\""]))
        #expect(result == "{\n  \"font\": {\n    \"size\": 14,\n    \"family\": \"Menlo\"\n  }\n}\n")
        #expect(try ConfigurationParser.parse(result).configuration.font.family == "Menlo")
    }

    @Test func `a section that is missing is added whole, and an empty object gets its first key`() throws {
        let result = try #require(patched("{}", ["scroll.wheel": "5", "scroll.trackpad": "2"]))
        let parsed = try ConfigurationParser.parse(result)
        #expect(parsed.issues.isEmpty)
        #expect(parsed.configuration.scroll.wheel == 5 && parsed.configuration.scroll.trackpad == 2)
        let more = try #require(patched("{ \"font\": { \"size\": 12 } }", ["window.dragStrip": "20"]))
        #expect(try ConfigurationParser.parse(more).configuration.window.dragStrip == 20)
        #expect(try ConfigurationParser.parse(more).configuration.font.size == 12)
    }

    @Test func `a trailing comma and a comment after the last member survive an addition`() throws {
        let text = "{\n  \"font\": { \"size\": 14, },\n  // end\n}\n"
        let result = try #require(patched(text, ["font.ligatures": "false"]))
        #expect(result.contains("// end"))
        #expect(try ConfigurationParser.parse(result).configuration.font.ligatures == false)
    }

    @Test func `quoted, single-quoted and bare keys are all found`() throws {
        let text = "{ font: { 'size': 14, \"ligatures\": true } }"
        let result = try #require(patched(text, ["font.size": "20", "font.ligatures": "false"]))
        let parsed = try ConfigurationParser.parse(result)
        #expect(parsed.configuration.font.size == 20 && parsed.configuration.font.ligatures == false)
    }

    @Test func `braces, commas and comment markers inside strings do not confuse it`() throws {
        let text = #"{ "font": { "family": "A } , // /* B", "size": 14 } }"#
        let result = try #require(patched(text, ["font.size": "15"]))
        let parsed = try ConfigurationParser.parse(result)
        #expect(parsed.configuration.font.family == "A } , // /* B")
        #expect(parsed.configuration.font.size == 15)
    }

    @Test func `a repeated key changes the last one, which is the one in force`() throws {
        let result = try #require(patched(#"{ "font": { "size": 1, "size": 2 } }"#, ["font.size": "9"]))
        #expect(try ConfigurationParser.parse(result).configuration.font.size == 9)
    }

    @Test func `a value that is not a section where a section is needed is replaced by one`() throws {
        let result = try #require(patched(#"{ "font": 3 }"#, ["font.size": "9"]))
        #expect(try ConfigurationParser.parse(result).configuration.font.size == 9)
    }

    @Test func `text that is not an object is refused`() {
        #expect(patched("[1,2]", ["a": "1"]) == nil)
        #expect(patched("{ \"a\": ", ["a": "1"]) == nil)
        #expect(patched("", ["a": "1"]) == nil)
    }

    @Test func `nothing to change returns the text as it is`() {
        let text = "// hello\n{ \"a\": 1 }\n"
        #expect(patched(text, [:]) == text)
    }

    @Test
    func `patching with what the writer writes for a configuration gives that configuration, whatever the file held`()
        throws
    {
        var target = Configuration()
        target.font.size = 17
        target.colors.background = [1, 2, 3]
        target.window.decorations = .native
        target.scroll.wheel = 7
        target.cursorBlinkTimeout = nil
        let starts = [
            "{}", "// c\n{ \"font\": { \"size\": 3 } }", "{ scroll: { 'wheel': 1, }, }",
            ConfigurationWriter.text(for: Configuration())
        ]
        for start in starts {
            let result = try #require(ConfigurationPatcher.patch(start, set: ConfigurationWriter.literals(for: target)))
            #expect(try ConfigurationParser.parse(result).configuration == target, "starting from \(start.prefix(30))")
        }
    }

    @Test func `saving a configuration changes only what differs from what the file says, and keeps the comments`()
        throws
    {
        let file = "// my terminal\n{\n  \"font\": { \"size\": 14 }, // sizes\n  \"scroll\": { \"wheel\": 2 }\n}\n"
        var edited = try ConfigurationParser.parse(file).configuration
        edited.font.size = 16
        edited.keyboard.optionAsMeta = true
        let result = try #require(ConfigurationPatcher.saved(edited, over: file))
        #expect(result.hasPrefix("// my terminal\n"))
        #expect(result.contains("// sizes"))
        #expect(result.contains("\"wheel\": 2"), "untouched keys stay as written")
        #expect(!result.contains("trackpad"), "keys at their default that the file never had are not added")
        #expect(try ConfigurationParser.parse(result).configuration == edited)
    }

    @Test func `a file that cannot be read is not patched`() {
        #expect(ConfigurationPatcher.saved(Configuration(), over: "{ nope") == nil)
    }
}
