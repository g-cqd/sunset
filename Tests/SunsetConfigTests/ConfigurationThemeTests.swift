import Testing

@testable import SunsetConfig

@Suite("Configuration: themes") struct ConfigurationThemeTests {
    private let nord = """
        { "font": { "family": "Iosevka", "size": 15 },
          "colors": { "background": "#2e3440", "foreground": "#d8dee9" },
          "window": { "material": "transparent", "blur": 30 }, "terminal": { "opacity": 0.8 },
          "appearance": { "tint": { "color": "#88c0d0", "alpha": 0.2 } } }
        """

    private func load(_ file: String, themes: [String: String]) throws(ConfigurationError) -> ConfigurationLoader.Result
    {
        try ConfigurationLoader.load(file) { themes[$0] }
    }

    @Test func `with no theme named the file is read as it is`() throws {
        let result = try load(#"{ "font": { "size": 12 } }"#, themes: ["nord": nord])
        #expect(result.configuration.font.size == 12 && result.configuration.font.family == Configuration().font.family)
        #expect(result.issues.isEmpty)
    }

    @Test func `a theme brings its visual settings, and the file's own keys beat it`() throws {
        let result = try load(
            #"{ "theme": "nord", "font": { "size": 12 }, "window": { "blur": 5 } }"#,
            themes: ["nord": nord]
        )
        #expect(result.issues.isEmpty)
        let configuration = result.configuration
        #expect(configuration.font.family == "Iosevka", "from the theme")
        #expect(configuration.font.size == 12, "the file beats the theme")
        #expect(configuration.colors.background == [0x2E, 0x34, 0x40])
        #expect(configuration.window.material == .fill && configuration.terminal.opacity == 0.8)
        #expect(configuration.window.blur == 5, "the file beats the theme")
        #expect(configuration.appearance.tintColor == [0x88, 0xC0, 0xD0])
        #expect(configuration.theme == "nord")
    }

    @Test func `a theme that does not exist is reported, and the file is still used`() throws {
        let result = try load(#"{ "theme": "missing", "font": { "size": 12 } }"#, themes: [:])
        #expect(result.configuration.font.size == 12)
        #expect(result.issues.contains { $0.path == "theme" && $0.message.contains("missing") })
    }

    @Test func `a theme may only set what is visual: other keys in it are reported and ignored`() throws {
        let theme =
            ##"{ "colors": { "cursor": "#ff0000" }, "scroll": { "wheel": 9 }, "keyboard": { "optionAsMeta": true }, "theme": "other" }"##
        let result = try load(#"{ "theme": "t" }"#, themes: ["t": theme])
        #expect(result.configuration.colors.cursor == [255, 0, 0])
        #expect(result.configuration.scroll.wheel == 3 && !result.configuration.keyboard.optionAsMeta)
        #expect(result.configuration.theme == "t")
        #expect(result.issues.map(\.path).sorted() == ["theme:keyboard", "theme:scroll", "theme:theme"])
    }

    @Test func `a theme with a wrong value reports it under the theme's name`() throws {
        let result = try load(#"{ "theme": "t" }"#, themes: ["t": #"{ "window": { "blur": 500 } }"#])
        #expect(result.issues.map(\.path) == ["theme:window.blur"])
        #expect(result.configuration.window.blur == 0)
    }

    @Test func `a theme that is not JSON is reported and not applied`() throws {
        let result = try load(#"{ "theme": "t", "font": { "size": 11 } }"#, themes: ["t": "{ nope"])
        #expect(result.configuration.font.size == 11)
        #expect(result.issues.contains { $0.path == "theme" && $0.message.contains("t") })
    }

    @Test func `theme names cannot walk out of the themes folder`() throws {
        #expect(ConfigurationLoader.isSafeThemeName("nord"))
        #expect(ConfigurationLoader.isSafeThemeName("solarized-dark_2"))
        #expect(!ConfigurationLoader.isSafeThemeName("../secret"))
        #expect(!ConfigurationLoader.isSafeThemeName("a/b"))
        #expect(!ConfigurationLoader.isSafeThemeName(""))
        #expect(!ConfigurationLoader.isSafeThemeName(".hidden"))
        let result = try load(#"{ "theme": "../x" }"#, themes: ["../x": nord])
        #expect(result.issues.contains { $0.path == "theme" })
        #expect(result.configuration.font.family == Configuration().font.family)
    }

    @Test func `the theme folder sits next to the file`() {
        #expect(
            ConfigurationLocation.themePath(named: "nord", besideConfig: "/h/.config/sunset/config.json")
                == "/h/.config/sunset/themes/nord.json"
        )
    }
}
