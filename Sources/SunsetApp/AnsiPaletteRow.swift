import AppKit
import SunsetConfig
import SunsetShell
import SwiftUI

/// The 16 ANSI colours as rows of colour wells: the normal colours above, their bright variants below; eight a row, or
/// four in a narrow pane.
struct AnsiPaletteRow: View {
    let config: any SettingsStore

    private static let names = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            Text("ANSI colors")
            ViewThatFits(in: .horizontal) {
                wells(perRow: 8)
                wells(perRow: 4)
            }
        }
    }

    /// The wells, `perRow` to a row, in the palette's order.
    private func wells(perRow: Int) -> some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            ForEach(0 ..< 16 / perRow, id: \.self) { row in
                HStack(spacing: Design.Space.m) {
                    ForEach(0 ..< perRow, id: \.self) { column in
                        well(row * perRow + column)
                    }
                }
            }
        }
    }

    private func well(_ index: Int) -> some View {
        let name = (index >= 8 ? "Bright " : "") + Self.names[index % 8]
        return ColorPicker(name, selection: binding(index), supportsOpacity: false)
            .labelsHidden()
            .help(name)
    }

    private func binding(_ index: Int) -> Binding<Color> {
        Binding(
            get: { Color(sRGBBytes: config.configuration.colors.ansi[index]) },
            set: { color in
                guard let bytes = color.sRGBBytes else { return }
                config.update { $0.colors.ansi[index] = bytes }
            }
        )
    }
}
