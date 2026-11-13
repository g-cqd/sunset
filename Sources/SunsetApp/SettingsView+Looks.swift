import SunsetConfig
import SunsetShell
import SwiftUI

/// The controls of the appearance, sidebar and tabs panes.
extension SettingsView {
    @ViewBuilder func moreControls(for id: String) -> some View {
        switch id {
            case "theme.name": themeField
            case "window.material": materialPicker("Window and sidebar background", config.binding(\.window.material))
            case "terminal.opacity":
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    number("Background opacity", \.terminal.opacity, range: 0 ... 1, step: 0.05, unit: "")
                    Text(
                        "How opaque the terminal screen's own background is. It only shows when the window background is not Opaque (Window / Appearance); "
                            + "the sidebar follows the window's settings."
                    )
                    .font(Design.Text.detail).foregroundStyle(.secondary)
                }
            case "terminal.clipboardWrite":
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    Toggle("Programs may copy to the clipboard", isOn: config.binding(\.terminal.clipboardWrite))
                    Text("What a program asks to copy (OSC 52), over ssh too. No program can read the clipboard.")
                        .font(Design.Text.detail).foregroundStyle(.secondary)
                }
            case "terminal.directory":
                TextField("New terminals start in", text: config.binding(\.terminal.directory), prompt: Text("~"))
            case "terminal.shellIntegration":
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    Toggle("Shell marks its prompts", isOn: config.binding(\.terminal.shellIntegration))
                    Text("For Previous Prompt and Next Prompt, in new zsh tabs. fish does it itself.")
                        .font(Design.Text.detail).foregroundStyle(.secondary)
                }
            case "window.blur": number("Window blur", \.window.blur, range: 0 ... 100, step: 1, unit: "pt")
            case "window.padding": number("Padding", \.window.padding, range: 0 ... 32, step: 1, unit: "pt")
            case "appearance.scheme":
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    Picker("Color scheme", selection: config.binding(\.appearance.scheme)) {
                        Text("Dark (locked)").tag(Configuration.Appearance.Scheme.dark)
                        Text("Light").tag(Configuration.Appearance.Scheme.light)
                        Text("Follow the system").tag(Configuration.Appearance.Scheme.system)
                    }
                    Text("For the terminal windows: the sidebar, glass and controls. This window follows the system.")
                        .font(Design.Text.detail).foregroundStyle(.secondary)
                }
            case "appearance.glass":
                Picker("Glass style", selection: config.binding(\.appearance.glass)) {
                    ForEach(Configuration.Appearance.Glass.allCases, id: \.self) { Text($0.rawValue.capitalized) }
                }
            case "appearance.barTint":
                Picker("Bars", selection: config.binding(\.appearance.barTint)) {
                    Text("Follow the color scheme").tag(Configuration.Appearance.BarTint.scheme)
                    Text("Dark").tag(Configuration.Appearance.BarTint.dark)
                    Text("Light").tag(Configuration.Appearance.BarTint.light)
                }
            case "appearance.barBlur":
                Picker("Under the bars", selection: config.binding(\.appearance.barBlur)) {
                    Text("Fading blur").tag(Configuration.Appearance.BarBlur.variable)
                    Text("The bar's surface").tag(Configuration.Appearance.BarBlur.surface)
                    Text("Nothing").tag(Configuration.Appearance.BarBlur.none)
                }
            case "appearance.tint": colorRow("Tint", \.appearance.tintColor, fallback: [48, 96, 255])
            case "appearance.tintAlpha":
                number("Tint strength", \.appearance.tintAlpha, range: 0 ... 1, step: 0.05, unit: "")
            default: layoutControls(for: id)
        }
    }

    @ViewBuilder func sidebarAndTabControls(for id: String) -> some View {
        switch id {
            case "sidebar.enabled":
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    Toggle("Show the sidebar", isOn: config.binding(\.sidebar.enabled))
                    Text("The sidebar lists the tabs. It needs tabs set to Native (the built-in bar replaces it).")
                        .font(Design.Text.detail).foregroundStyle(.secondary)
                }
            case "sidebar.side":
                Picker("Side", selection: config.binding(\.sidebar.side)) {
                    Text("Left").tag(Configuration.Side.left)
                    Text("Right").tag(Configuration.Side.right)
                }
            case "sidebar.width": number("Width", \.sidebar.width, range: 120 ... 480, step: 5, unit: "pt")
            case "sidebar.padding":
                number("Space around the terminal", \.sidebar.padding, range: 0 ... 16, step: 1, unit: "pt")
            case "tabs.icon":
                Toggle("Show the folder or command icon", isOn: config.binding(\.tabs.bar.showIcon))
            case "tabs.restore":
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    Toggle("Restore tabs at launch", isOn: config.binding(\.tabs.restore))
                    Text(
                        "The windows, tabs and splits come back, each pane as a new shell in the directory it was in. Programs that were running are not restarted."
                    )
                    .font(Design.Text.detail).foregroundStyle(.secondary)
                }
            case "tabs.keepRunningForFavorites":
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    Toggle(
                        "Keep running while a favourite is open",
                        isOn: config.binding(\.tabs.keepRunningForFavorites)
                    )
                    Text(
                        "Closing the last window does not quit Sunset while something in Favorites is open; it goes on running, and a new window shows it again."
                    )
                    .font(Design.Text.detail).foregroundStyle(.secondary)
                }
            case "tabs.askBeforeQuit": quitPicker
            case "tabs.confirmClose":
                VStack(alignment: .leading, spacing: Design.Space.xs) {
                    Toggle("Confirm closing a busy tab", isOn: config.binding(\.tabs.confirmClose))
                    Text(
                        "When a foreground command is running, the first click on the close button or ⌘W tints the tab red; a second one closes it."
                    )
                    .font(Design.Text.detail).foregroundStyle(.secondary)
                }
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
            case "tabs.title", "tabs.directory", "tabs.monospacedDirectory", "tabs.progress": tabLineToggle(id)
            default: EmptyView()
        }
    }

    private func materialPicker(_ name: String, _ selection: Binding<Configuration.Material>) -> some View {
        Picker(name, selection: selection) {
            Text("Opaque").tag(Configuration.Material.opaque)
            Text("Material").tag(Configuration.Material.material)
            Text("Glass").tag(Configuration.Material.glass)
            Text("Colour fill").tag(Configuration.Material.fill)
        }
    }

    private var themeField: some View {
        VStack(alignment: .leading, spacing: Design.Space.xs) {
            TextField("Theme", text: config.textBinding(\.theme), prompt: Text("nord"))
            Text(
                "A file themes/<name>.json beside the configuration file; it can set the font, colours, window, sidebar and appearance. Your own keys win."
            )
            .font(Design.Text.detail).foregroundStyle(.secondary)
        }
    }

    private var quitPicker: some View {
        Picker("Ask before quitting", selection: config.binding(\.tabs.askBeforeQuit)) {
            Text("Never").tag(Configuration.Tabs.QuitAsk.never)
            Text("When something would be lost").tag(Configuration.Tabs.QuitAsk.whenLosing)
            Text("Always").tag(Configuration.Tabs.QuitAsk.always)
        }
    }

    /// What a tab's row shows.
    @ViewBuilder private func tabLineToggle(_ id: String) -> some View {
        switch id {
            case "tabs.title": Toggle("Show the title", isOn: config.binding(\.tabs.bar.showTitle))
            case "tabs.directory": Toggle("Show the working directory", isOn: config.binding(\.tabs.bar.showDirectory))
            case "tabs.monospacedDirectory":
                Toggle("Second line in monospace", isOn: config.binding(\.tabs.bar.monospacedDirectory))
            default: Toggle("Show progress", isOn: config.binding(\.tabs.bar.showProgress))
        }
    }
}
