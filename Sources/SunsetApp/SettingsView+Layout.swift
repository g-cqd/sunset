import SunsetConfig
import SunsetMetrics
import SwiftUI

/// The controls of the Layout pane: one number row per metric of `Configuration.Layout.fields`, and the two radii that can follow the window's corners.
extension SettingsView {
    private var layoutPath: WritableKeyPath<Configuration, Configuration.Layout> { \.layout }

    @ViewBuilder func layoutControls(for id: String) -> some View {
        if let field = Configuration.Layout.fields.first(where: { "layout.\($0.key)" == id }) {
            number(
                field.title,
                layoutPath.appending(path: field.path),
                range: field.range,
                step: field.step,
                unit: field.unit
            )
        } else if id == "layout.terminalRadius" {
            radiusRow("Terminal card corner radius", \.layout.terminalRadius)
        } else if id == "layout.panelRadius" {
            radiusRow("Floating sidebar corner radius", \.layout.panelRadius)
        } else {
            sidebarAndTabControls(for: id)
        }
    }

    /// A radius that is either the window's (concentric: its radius minus the margin) or a number of points of its own.
    private func radiusRow(_ name: String, _ keyPath: WritableKeyPath<Configuration, Double?>) -> some View {
        let follows = Binding(
            get: { config.configuration[keyPath: keyPath] == nil },
            set: { follow in config.update { $0[keyPath: keyPath] = follow ? nil : 10 } }
        )
        let points = Binding(
            get: { config.configuration[keyPath: keyPath] ?? 10 },
            set: { new in config.update { $0[keyPath: keyPath] = new } }
        )
        return VStack(alignment: .leading, spacing: 4) {
            Toggle("\(name): match the window", isOn: follows)
            NumberRow(name: name, value: points, range: 0 ... 40, step: 1, unit: "pt")
                .disabled(follows.wrappedValue)
        }
    }
}
