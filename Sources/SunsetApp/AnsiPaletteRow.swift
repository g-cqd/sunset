import AppKit
import SunsetConfig
import SwiftUI

/// The 16 ANSI colours as two rows of colour wells: the normal colours above, their bright variants below.
struct AnsiPaletteRow: View {
    let config: AppConfiguration

    private static let names = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ANSI colors")
            ForEach(0 ..< 2, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0 ..< 8, id: \.self) { column in
                        let index = row * 8 + column
                        ColorPicker(
                            (row == 1 ? "Bright " : "") + Self.names[column],
                            selection: binding(index),
                            supportsOpacity: false
                        )
                        .labelsHidden()
                        .help((row == 1 ? "Bright " : "") + Self.names[column])
                    }
                }
            }
        }
    }

    private func binding(_ index: Int) -> Binding<Color> {
        Binding(
            get: {
                let bytes = config.configuration.colors.ansi[index]
                return Color(
                    .sRGB,
                    red: Double(bytes[0]) / 255,
                    green: Double(bytes[1]) / 255,
                    blue: Double(bytes[2]) / 255
                )
            },
            set: { color in
                guard let converted = NSColor(color).usingColorSpace(.sRGB) else { return }
                let bytes = [converted.redComponent, converted.greenComponent, converted.blueComponent]
                    .map { UInt8(max(0, min(255, ($0 * 255).rounded()))) }
                config.update { $0.colors.ansi[index] = bytes }
            }
        )
    }
}
