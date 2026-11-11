import SunsetConfig
import SunsetShell
import SunsetShellBridge
import Testing

@Suite("Shell settings from the configuration") struct ShellSettingsMappingTests {
    /// The stored properties of a value, by name, as text.
    private func fields(_ value: Any) -> [String: String] {
        var result: [String: String] = [:]
        for child in Mirror(reflecting: value).children {
            if let label = child.label { result[label] = "\(child.value)" }
        }
        return result
    }

    /// A configuration whose every `layout.*` number is different from every other, and from its default.
    private func distinct() -> Configuration {
        var configuration = Configuration()
        for (index, field) in Configuration.Layout.fields.enumerated() {
            configuration.layout[keyPath: field.path] = 100 + Double(index)
        }
        configuration.layout.terminalRadius = 77
        configuration.layout.panelRadius = 78
        return configuration
    }

    @Test func `every layout value of the configuration reaches the shell under the same name`() {
        let configuration = distinct()
        let from = fields(configuration.layout)
        let into = fields(ShellSettings.Layout(configuration.layout))
        #expect(from.count > 25, "the reflection must see the layout: \(from.count) values")
        #expect(Set(from.keys) == Set(into.keys))
        for (name, value) in from { #expect(into[name] == value, "layout.\(name)") }
    }

    @Test func `the layout's defaults are the configuration's`() {
        #expect(fields(ShellSettings.Layout()) == fields(Configuration.Layout()))
        #expect(fields(ShellSettings.Layout(Configuration.Layout())) == fields(ShellSettings.Layout()))
    }

    @Test func `the sidebar's values reach the shell, and its defaults are the configuration's`() {
        #expect(fields(ShellSettings.Sidebar()) == fields(Configuration.Sidebar()))
        var configuration = Configuration()
        configuration.sidebar.enabled = false
        configuration.sidebar.width = 301
        configuration.sidebar.padding = 9
        configuration.sidebar.autoHide = true
        configuration.sidebar.side = .right
        let settings = ShellSettings(configuration)
        #expect(fields(settings.sidebar) == fields(configuration.sidebar))
        #expect(settings.sidebar.side == .right)
    }

    @Test func `what a tab's row shows reaches the shell, each switch by itself`() {
        #expect(fields(ShellSettings.Bar()) == fields(Configuration.Tabs.Bar()))
        let switches: [WritableKeyPath<Configuration.Tabs.Bar, Bool>] = [
            \.showTitle, \.showIcon, \.showDirectory, \.showProgress
        ]
        for off in switches {
            var configuration = Configuration()
            configuration.tabs.bar[keyPath: off] = false
            configuration.tabs.bar.position = .top
            #expect(fields(ShellSettings(configuration).tabs.bar) == fields(configuration.tabs.bar))
        }
    }

    @Test func `the whole configuration maps as its parts do`() {
        let configuration = distinct()
        #expect(ShellSettings(configuration).layout == ShellSettings.Layout(configuration.layout))
    }
}
