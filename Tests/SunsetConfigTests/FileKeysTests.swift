import Testing

@testable import SunsetConfig

/// The file's keys follow Settings' sections (design 0009); a file with the former keys is still read, and said to be
/// written again.
@Suite("The file's keys")
struct FileKeysTests {
    @Test func `the new keys and the former ones read the same; the former are flagged`() throws {
        let new = try ConfigurationParser.parse(
            ##"{ "terminal": { "font": { "size": 15 }, "colors": { "background": "#101010" }, "scrollback": 500, "padding": 4 }, "appearance": { "blur": 10 }, "documents": { "sort": "name" } }"##
        )
        let old = try ConfigurationParser.parse(
            ##"{ "font": { "size": 15 }, "colors": { "background": "#101010" }, "scrollback": { "lines": 500 }, "window": { "padding": 4, "blur": 10 }, "sidebar": { "documentSort": "name" } }"##
        )
        #expect(new.issues.isEmpty && old.issues.isEmpty)
        #expect(new.configuration == old.configuration)
        #expect(new.configuration.font.size == 15 && new.configuration.scrollbackLines == 500)
        #expect(!new.hasFormerKeys && old.hasFormerKeys)
    }

    @Test func `the file is written under the new keys, each section's together, and reads back`() throws {
        var configuration = Configuration()
        configuration.font.size = 17
        let text = ConfigurationWriter.text(for: configuration)
        #expect(!text.contains("\"scrollback\": {") && text.contains("\"documentSort\"") == false)
        let back = try ConfigurationParser.parse(text)
        #expect(back.issues.isEmpty && back.configuration == configuration && !back.hasFormerKeys)
        #expect(
            FileKeys.file("font.size") == "terminal.font.size"
                && FileKeys.inside("terminal.scrollback") == "scrollback.lines"
        )
    }
}

extension FileKeysTests {
    @Test func `a file with the former keys is moved as it was written, comments kept, and reads the same`() throws {
        let former = """
            {
              // my font
              "font": { "size": 15 },
              "scrollback": { "lines": 500 },
              "terminal": { "opacity": 0.9 }
            }
            """
        let moved = try #require(ConfigurationPatcher.movingFormerKeys(former))
        #expect(moved.contains("// my font"))
        let before = try ConfigurationParser.parse(former)
        let after = try ConfigurationParser.parse(moved)
        #expect(after.configuration == before.configuration && after.issues.isEmpty && !after.hasFormerKeys)
    }
}
