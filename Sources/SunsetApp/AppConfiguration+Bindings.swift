import SunsetConfig
import SwiftUI

/// Bindings from the Settings window to the configuration: reading is the configuration, writing is `update` (which saves the file).
extension AppConfiguration {
    func binding<Value: Sendable>(_ keyPath: WritableKeyPath<Configuration, Value>) -> Binding<Value> {
        Binding(
            get: { self.configuration[keyPath: keyPath] },
            set: { value in self.update { $0[keyPath: keyPath] = value } }
        )
    }

    /// An optional setting as an "on" switch and a value: off is nil.
    func switchBinding<Value: Sendable>(
        _ keyPath: WritableKeyPath<Configuration, Value?>,
        whenOn value: Value
    ) -> Binding<Bool> {
        Binding(
            get: { self.configuration[keyPath: keyPath] != nil },
            set: { on in
                self.update { $0[keyPath: keyPath] = on ? (self.configuration[keyPath: keyPath] ?? value) : nil }
            }
        )
    }

    /// A text setting where the empty string is "not set".
    func textBinding(_ keyPath: WritableKeyPath<Configuration, String?>) -> Binding<String> {
        Binding(
            get: { self.configuration[keyPath: keyPath] ?? "" },
            set: { text in self.update { $0[keyPath: keyPath] = text.isEmpty ? nil : text } }
        )
    }

    /// A colour setting (`#rrggbb` in the file, sRGB): the picker's colour in, three bytes out.
    func colorBinding(_ keyPath: WritableKeyPath<Configuration, [UInt8]?>, fallback: [UInt8]) -> Binding<Color> {
        Binding(
            get: {
                let bytes = self.configuration[keyPath: keyPath] ?? fallback
                return Color(
                    .sRGB,
                    red: Double(bytes[0]) / 255,
                    green: Double(bytes[1]) / 255,
                    blue: Double(bytes[2]) / 255,
                    opacity: 1
                )
            },
            set: { color in
                guard let converted = NSColor(color).usingColorSpace(.sRGB) else { return }
                let bytes = [converted.redComponent, converted.greenComponent, converted.blueComponent]
                    .map {
                        UInt8(max(0, min(255, ($0 * 255).rounded())))
                    }
                self.update { $0[keyPath: keyPath] = bytes }
            }
        )
    }
}
