import Testing

@testable import SunsetConfig

@Suite("Configuration: materials, sidebar, tabs, theme") struct ConfigurationAppearanceTests {
    private func read(_ text: String) throws(ConfigurationError) -> ConfigurationParser.Result {
        try ConfigurationParser.parse(text)
    }

    @Test func `the defaults: opaque, no padding, no blur, no sidebar, native tabs, regular glass`() throws {
        let configuration = try read("{}").configuration
        #expect(configuration.window.material == .opaque)
        #expect(
            configuration.window.padding == 0 && configuration.window.blur == 0 && configuration.window.opacity == 0.8
        )
        #expect(
            !configuration.sidebar.enabled && configuration.sidebar.width == 200 && configuration.sidebar.padding == 3
        )
        #expect(configuration.sidebar.material == .material && configuration.sidebar.blur == 0)
        #expect(configuration.appearance.glass == .regular)
        #expect(configuration.appearance.tintColor == nil && configuration.appearance.tintAlpha == 0.25)
        #expect(configuration.tabs.mode == .native)
        #expect(configuration.tabs.bar == Configuration.Tabs.Bar())
        #expect(configuration.theme == nil)
    }

    @Test func `every new key is read`() throws {
        let result = try read(
            """
            {
              "window": { "material": "transparent", "opacity": 0.6, "blur": 40, "padding": 6 },
              "sidebar": { "enabled": true, "width": 240, "padding": 4, "material": "glass", "blur": 12 },
              "appearance": { "glass": "clear", "tint": { "color": "#336699", "alpha": 0.4 } },
              "tabs": { "mode": "internal", "bar": { "position": "bottom", "title": false, "directory": true, "progress": false } },
              "theme": "nord"
            }
            """
        )
        #expect(result.issues.isEmpty)
        let configuration = result.configuration
        #expect(configuration.window.material == .transparent && configuration.window.opacity == 0.6)
        #expect(configuration.window.blur == 40 && configuration.window.padding == 6)
        #expect(
            configuration.sidebar.enabled && configuration.sidebar.width == 240 && configuration.sidebar.padding == 4
        )
        #expect(configuration.sidebar.material == .glass && configuration.sidebar.blur == 12)
        #expect(configuration.appearance.glass == .clear)
        #expect(configuration.appearance.tintColor == [0x33, 0x66, 0x99] && configuration.appearance.tintAlpha == 0.4)
        #expect(configuration.tabs.mode == .internal)
        #expect(configuration.tabs.bar.position == .bottom)
        #expect(
            !configuration.tabs.bar.showTitle && configuration.tabs.bar.showDirectory
                && !configuration.tabs.bar.showProgress
        )
        #expect(configuration.theme == "nord")
    }

    @Test func `values out of range or unknown names are reported and keep the default`() throws {
        let result = try read(
            """
            { "window": { "material": "wood", "blur": 101, "opacity": 2, "padding": -1 },
              "sidebar": { "width": 50, "padding": 9 }, "tabs": { "mode": "kitty" }, "appearance": { "glass": "frosted" } }
            """
        )
        #expect(
            result.issues.map(\.path).sorted() == [
                "appearance.glass", "sidebar.padding", "sidebar.width", "tabs.mode", "window.blur", "window.material",
                "window.opacity", "window.padding"
            ]
        )
        #expect(result.configuration.window == Configuration.Window())
        #expect(result.configuration.tabs.mode == .native)
        #expect(result.issues.first { $0.path == "sidebar.padding" }?.message.contains("2") == true)
    }

    @Test func `the sidebar and the window are separate: blur 0 to 100 each`() throws {
        let result = try read(#"{ "window": { "blur": 100 }, "sidebar": { "blur": 100 } }"#)
        #expect(result.issues.isEmpty)
        #expect(result.configuration.window.blur == 100 && result.configuration.sidebar.blur == 100)
    }

    @Test func `groups: the window look, the sidebar, the tabs and the theme are separate changes`() {
        var new = Configuration()
        new.sidebar.enabled = true
        #expect(new.changes(from: Configuration()) == [.sidebar])
        var tabs = Configuration()
        tabs.tabs.mode = .none
        #expect(tabs.changes(from: Configuration()) == [.tabs])
        var look = Configuration()
        look.appearance.glass = .clear
        #expect(look.changes(from: Configuration()) == [.appearance])
        var theme = Configuration()
        theme.theme = "x"
        #expect(theme.changes(from: Configuration()) == [.theme])
    }
}
