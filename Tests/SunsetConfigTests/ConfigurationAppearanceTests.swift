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
            configuration.window.padding == 0 && configuration.window.blur == 0 && configuration.terminal.opacity == 0.8
        )
        #expect(
            !configuration.sidebar.enabled && configuration.sidebar.width == 200 && configuration.sidebar.padding == 6
        )
        #expect(
            configuration.sidebar.autoHide,
            "hidden until the pointer is at the leading edge, then a floating glass panel"
        )
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
              "window": { "material": "transparent", "blur": 40, "padding": 6 },
              "terminal": { "opacity": 0.6 },
              "sidebar": { "enabled": true, "width": 240, "padding": 4 },
              "appearance": { "glass": "clear", "tint": { "color": "#336699", "alpha": 0.4 } },
              "tabs": { "mode": "internal", "bar": { "position": "bottom", "title": false, "directory": true, "progress": false } },
              "theme": "nord"
            }
            """
        )
        #expect(result.issues.isEmpty)
        let configuration = result.configuration
        #expect(configuration.window.material == .transparent && configuration.terminal.opacity == 0.6)
        #expect(configuration.window.blur == 40 && configuration.window.padding == 6)
        #expect(
            configuration.sidebar.enabled && configuration.sidebar.width == 240 && configuration.sidebar.padding == 4
        )
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
            { "window": { "material": "wood", "blur": 101, "padding": -1 }, "terminal": { "opacity": 2 },
              "sidebar": { "width": 50, "padding": 17 }, "tabs": { "mode": "kitty" }, "appearance": { "glass": "frosted" } }
            """
        )
        #expect(
            result.issues.map(\.path).sorted() == [
                "appearance.glass", "sidebar.padding", "sidebar.width", "tabs.mode", "terminal.opacity", "window.blur",
                "window.material", "window.padding"
            ]
        )
        #expect(result.configuration.window == Configuration.Window())
        #expect(result.configuration.tabs.mode == .native)
        #expect(result.issues.first { $0.path == "sidebar.padding" }?.message.contains("16") == true)
    }

    @Test func `the sidebar can stay: autoHide is a flag`() throws {
        let kept = try read(#"{ "sidebar": { "autoHide": false } }"#)
        #expect(kept.issues.isEmpty && !kept.configuration.sidebar.autoHide)
        #expect(try read(#"{ "sidebar": { "autoHide": "yes" } }"#).issues.map(\.path) == ["sidebar.autoHide"])
    }

    @Test
    func
        `the sidebar has no background settings of its own: the old keys are accepted and ignored, window.opacity moved to the terminal`()
        throws
    {
        let old = try read(
            #"{ "window": { "blur": 100, "opacity": 0.5 }, "sidebar": { "blur": 10, "material": "glass", "width": 220 } }"#
        )
        #expect(old.issues.isEmpty, "a file written before the change still loads without warnings")
        #expect(old.configuration.window.blur == 100 && old.configuration.sidebar.width == 220)
        #expect(old.configuration.terminal.opacity == 0.5, "the old window.opacity is the terminal's now")
        let both = try read(#"{ "window": { "opacity": 0.5 }, "terminal": { "opacity": 0.7 } }"#)
        #expect(both.configuration.terminal.opacity == 0.7, "the new key wins whatever the order")
        #expect(try read(#"{ "terminal": { "opacity": 0.5 } }"#).configuration.terminal.opacity == 0.5)
        #expect(try read(#"{ "window": { "opacity": 5 } }"#).issues.map(\.path) == ["window.opacity"])
    }

    @Test func `the terminal windows are locked to the dark scheme unless the file says otherwise`() throws {
        #expect(Configuration().appearance.scheme == .dark)
        #expect(try read(#"{ "appearance": { "scheme": "system" } }"#).configuration.appearance.scheme == .system)
        #expect(try read(#"{ "appearance": { "scheme": "light" } }"#).configuration.appearance.scheme == .light)
        let bad = try read(#"{ "appearance": { "scheme": "sepia" } }"#)
        #expect(bad.issues.map(\.path) == ["appearance.scheme"])
        #expect(bad.configuration.appearance.scheme == .dark)
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
