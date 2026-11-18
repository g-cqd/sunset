import SunsetConfig
import SwiftUI

/// Bindings from the Settings window to the configuration: reading is the configuration, writing is `update` (which saves the file).
/// Where Settings reads and writes: all profiles' settings (`AppConfiguration`, the file), or one profile's own
/// (`ProfileSettingsStore`, roadmap 0050).
@MainActor protocol SettingsStore: AnyObject {
    var configuration: Configuration { get }
    func update(_ edit: (inout Configuration) -> Void)
}

extension AppConfiguration: SettingsStore {}

extension SettingsStore {
    func binding<Value: Sendable>(_ keyPath: WritableKeyPath<Configuration, Value>) -> Binding<Value> {
        Binding(
            get: { self.configuration[keyPath: keyPath] },
            set: { value in self.update { $0[keyPath: keyPath] = value } }
        )
    }

    /// An option of Settings: reading is the configuration, writing is `update`.
    func binding<Value>(_ value: SettingsValue<Value>) -> Binding<Value> {
        Binding(
            get: { value.get(self.configuration) },
            set: { new in self.update { value.set(&$0, new) } }
        )
    }

    /// An optional setting as an "on" switch and a value: off is nil.
    func switchBinding<Value>(_ value: SettingsValue<Value?>, whenOn fallback: Value) -> Binding<Bool> {
        Binding(
            get: { value.get(self.configuration) != nil },
            set: { on in self.update { value.set(&$0, on ? (value.get($0) ?? fallback) : nil) } }
        )
    }

    /// A text setting where the empty string is "not set".
    func textBinding(_ value: SettingsValue<String?>) -> Binding<String> {
        Binding(
            get: { value.get(self.configuration) ?? "" },
            set: { text in self.update { value.set(&$0, text.isEmpty ? nil : text) } }
        )
    }

    /// A colour setting (`#rrggbb` in the file, sRGB): the picker's colour in, three bytes out.
    func colorBinding(_ value: SettingsValue<[UInt8]?>, fallback: [UInt8]) -> Binding<Color> {
        Binding(
            get: {
                let bytes = value.get(self.configuration) ?? fallback
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
                self.update { value.set(&$0, bytes) }
            }
        )
    }
}
