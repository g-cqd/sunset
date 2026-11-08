import SunsetConfig
import SwiftUI

/// The controls of the appearance, sidebar and tabs panes.
extension SettingsView {
    @ViewBuilder func moreControls(for id: String) -> some View {
        switch id {
            case "theme.name": themeField
            case "window.material": materialPicker("Window background", config.binding(\.window.material))
            case "window.opacity": number("Background opacity", \.window.opacity, range: 0 ... 1, step: 0.05, unit: "")
            case "window.blur": number("Window blur", \.window.blur, range: 0 ... 100, step: 1, unit: "pt")
            case "window.padding": number("Padding", \.window.padding, range: 0 ... 32, step: 1, unit: "pt")
            case "appearance.glass":
                Picker("Glass style", selection: config.binding(\.appearance.glass)) {
                    ForEach(Configuration.Appearance.Glass.allCases, id: \.self) { Text($0.rawValue.capitalized) }
                }
            case "appearance.tint": colorRow("Tint", \.appearance.tintColor, fallback: [48, 96, 255])
            case "appearance.tintAlpha":
                number("Tint strength", \.appearance.tintAlpha, range: 0 ... 1, step: 0.05, unit: "")
            default: sidebarAndTabControls(for: id)
        }
    }

    @ViewBuilder private func sidebarAndTabControls(for id: String) -> some View {
        switch id {
            case "sidebar.enabled":
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Show the sidebar", isOn: config.binding(\.sidebar.enabled))
                    Text("The sidebar lists the tabs. It needs tabs set to Native (the built-in bar replaces it).")
                        .font(.caption).foregroundStyle(.secondary)
                }
            case "sidebar.width": number("Width", \.sidebar.width, range: 120 ... 480, step: 5, unit: "pt")
            case "sidebar.padding":
                number("Space around the terminal", \.sidebar.padding, range: 0 ... 16, step: 1, unit: "pt")
            case "sidebar.material": materialPicker("Sidebar background", config.binding(\.sidebar.material))
            case "sidebar.blur": number("Sidebar blur", \.sidebar.blur, range: 0 ... 100, step: 1, unit: "pt")
            case "tabs.mode":
                Picker("Tabs", selection: config.binding(\.tabs.mode)) {
                    Text("None (one terminal per window)").tag(Configuration.Tabs.Mode.none)
                    Text("Native (system tabs)").tag(Configuration.Tabs.Mode.native)
                    Text("Built-in (a bar in the window)").tag(Configuration.Tabs.Mode.internal)
                }
            case "tabs.position":
                Picker("Built-in bar position", selection: config.binding(\.tabs.bar.position)) {
                    ForEach(Configuration.Tabs.Bar.Position.allCases, id: \.self) { Text($0.rawValue.capitalized) }
                }
            case "tabs.title": Toggle("Show the title", isOn: config.binding(\.tabs.bar.showTitle))
            case "tabs.directory": Toggle("Show the working directory", isOn: config.binding(\.tabs.bar.showDirectory))
            case "tabs.progress": Toggle("Show progress", isOn: config.binding(\.tabs.bar.showProgress))
            default: EmptyView()
        }
    }

    private func materialPicker(_ name: String, _ selection: Binding<Configuration.Material>) -> some View {
        Picker(name, selection: selection) {
            Text("Opaque").tag(Configuration.Material.opaque)
            Text("Material").tag(Configuration.Material.material)
            Text("Glass").tag(Configuration.Material.glass)
            Text("Transparent").tag(Configuration.Material.transparent)
        }
    }

    private var themeField: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Theme", text: config.textBinding(\.theme), prompt: Text("nord"))
            Text(
                "A file themes/<name>.json beside the configuration file; it can set the font, colours, window, sidebar and appearance. Your own keys win."
            )
            .font(.caption).foregroundStyle(.secondary)
        }
    }
}
