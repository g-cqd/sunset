import Testing

@testable import SunsetConfig

@Suite("Configuration: writing a file") struct ConfigurationWriterTests {
    private func everythingSet() -> Configuration {
        var configuration = Configuration()
        configuration.font.family = "JetBrains Mono"
        configuration.font.size = 15.5
        configuration.font.ligatures = false
        configuration.font.features = "zero, ss01, cv02=3"
        configuration.colors.foreground = [0xE0, 0xE1, 0xE2]
        configuration.colors.background = [0x01, 0x02, 0x03]
        configuration.colors.cursor = [0xFF, 0x88, 0x00]
        configuration.window.decorations = .native
        configuration.window.trafficLightsX = 20
        configuration.window.trafficLightsY = 8.5
        configuration.window.dragStrip = 24
        configuration.scroll.trackpad = 0.6
        configuration.scroll.wheel = 5
        configuration.scrollbackLines = 50_000
        configuration.cursorBlinkTimeout = 30
        configuration.renderer = .cpu
        configuration.keyboard.optionAsMeta = true
        configuration.window.material = .transparent
        configuration.terminal.opacity = 0.6
        configuration.terminal.clipboardWrite = false
        configuration.terminal.shellIntegration = false
        configuration.window.blur = 40
        configuration.window.padding = 6
        configuration.sidebar.enabled = true
        configuration.sidebar.width = 240
        configuration.sidebar.padding = 4
        configuration.appearance.glass = .clear
        configuration.appearance.scheme = .light
        configuration.appearance.tintColor = [0x33, 0x66, 0x99]
        configuration.appearance.tintAlpha = 0.4
        configuration.tabs.mode = .internal
        configuration.tabs.bar.position = .bottom
        configuration.tabs.bar.showTitle = false
        configuration.tabs.bar.showDirectory = true
        configuration.tabs.bar.showProgress = false
        configuration.theme = "nord"
        return configuration
    }

    private func roundTrip(_ configuration: Configuration) throws -> ConfigurationParser.Result {
        try ConfigurationParser.parse(ConfigurationWriter.text(for: configuration))
    }

    @Test func `what is written reads back as the same configuration, with nothing to report`() throws {
        let configuration = everythingSet()
        let result = try roundTrip(configuration)
        #expect(result.issues.isEmpty)
        #expect(result.configuration == configuration)
    }

    @Test func `the defaults round-trip too, including a cursor that blinks for ever`() throws {
        #expect(try roundTrip(Configuration()).configuration == Configuration())
        var forever = Configuration()
        forever.cursorBlinkTimeout = nil
        #expect(try roundTrip(forever).configuration == forever)
        var unnamed = Configuration()
        unnamed.font.family = nil
        #expect(try roundTrip(unnamed).configuration.font.family == nil)
    }

    @Test func `every key the reader knows is in the file, so the file shows what can be set`() throws {
        let text = ConfigurationWriter.text(for: Configuration())
        #expect(
            ConfigurationKeys.all.count == 78,
            "a key was added or removed: the list, the reader and the writer move together"
        )
        for key in ConfigurationKeys.all {
            let name = key.split(separator: ".").last.map(String.init) ?? key
            #expect(text.contains("\"\(name)\""), "the key \(key) is missing from the written file")
        }
    }

    @Test func `text with quotes, backslashes and control characters in it survives`() throws {
        var configuration = Configuration()
        configuration.font.family = "My \"Mono\" \\ Font\u{1}\n"
        configuration.font.features = "a\tb"
        #expect(try roundTrip(configuration).configuration == configuration)
    }

    @Test func `the written text is stable: writing what was read gives the same text`() throws {
        let first = ConfigurationWriter.text(for: everythingSet())
        let second = ConfigurationWriter.text(for: try ConfigurationParser.parse(first).configuration)
        #expect(first == second)
    }
}
