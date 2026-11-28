import AppKit
import SunsetConfig
import SunsetShell
import SwiftUI

/// The 16 ANSI colours as rows of colour wells: the normal colours above, their bright variants below; eight a row, or
/// four in a narrow pane. `config` is the scheme Settings shows (`SchemeSettingsRow.store`, design 0009).
struct AnsiPaletteRow: View {
    let config: any SettingsStore

    private static let names = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            Text("ANSI colors")
            wells(config)
        }
    }

    private func wells(_ store: any SettingsStore) -> some View {
        ViewThatFits(in: .horizontal) {
            wells(store, perRow: 8)
            wells(store, perRow: 4)
        }
    }

    /// The wells, `perRow` to a row, in the palette's order.
    private func wells(_ store: any SettingsStore, perRow: Int) -> some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            ForEach(0 ..< 16 / perRow, id: \.self) { row in
                HStack(spacing: Design.Space.m) {
                    ForEach(0 ..< perRow, id: \.self) { column in
                        well(store, row * perRow + column)
                    }
                }
            }
        }
    }

    private func well(_ store: any SettingsStore, _ index: Int) -> some View {
        let name = (index >= 8 ? "Bright " : "") + Self.names[index % 8]
        return ColorPicker(name, selection: binding(store, index), supportsOpacity: false)
            .labelsHidden()
            .help(name)
    }

    private func binding(_ store: any SettingsStore, _ index: Int) -> Binding<Color> {
        Binding(
            get: { Color(sRGBBytes: store.configuration.colors.ansi[index]) },
            set: { color in
                guard let bytes = color.sRGBBytes else { return }
                store.update { $0.colors.ansi[index] = bytes }
            }
        )
    }
}
