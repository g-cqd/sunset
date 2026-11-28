/// Which scheme the look settings show in Settings (design 0009): macOS's own values, read only, or Sunset's in light or in
/// dark, where a change is that scheme's only.
enum SchemeEditing: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
            case .system: "System"
            case .light: "Light"
            case .dark: "Dark"
        }
    }

    /// The scheme its values are of: System's is the one on screen.
    func isLight(onScreen: Bool) -> Bool {
        self == .system ? onScreen : self == .light
    }
}
