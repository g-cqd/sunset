import SunsetConfig
import SwiftUI

/// Bindings from the Settings window to the configuration: reading is the configuration, writing is `update` (which saves the file).
/// Where Settings reads and writes: all profiles' settings (`AppConfiguration`, the file), or one profile's own
/// (`ProfileSettingsStore`, roadmap 0050).
@MainActor protocol SettingsStore: AnyObject {
    var configuration: Configuration { get }
    func update(_ edit: (inout Configuration) -> Void)
    /// The profile whose own site rules are listed (roadmap 0050 E); nil: all profiles' (and the first profile's).
    var profileID: UUID? { get }
}

extension AppConfiguration: SettingsStore {
    var profileID: UUID? {
        nil
    }
}

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
            get: { Color(sRGBBytes: value.get(self.configuration) ?? fallback) },
            set: { color in
                guard let bytes = color.sRGBBytes else { return }
                self.update { value.set(&$0, bytes) }
            }
        )
    }
}
