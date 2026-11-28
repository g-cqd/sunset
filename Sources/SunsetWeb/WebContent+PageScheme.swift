import AppKit
import SunsetWebModel

extension WebContent {
    /// Its page in the scheme its settings ask for (`appearance.contentFollows`): its window's, the system's, light or dark. A page
    /// with a dark mode of its own (`prefers-color-scheme`) follows it; WebKit leaves the others as they are.
    package func applyPageScheme() {
        guard let webView else { return }
        let name: NSAppearance.Name? =
            switch settings.pageScheme {
                case .window: nil
                case .light: .aqua
                case .dark: .darkAqua
                case .system: Self.systemIsDark ? .darkAqua : .aqua
            }
        webView.appearance = name.flatMap(NSAppearance.init(named:))
    }

    /// Whether the Mac is in dark mode now, whatever Sunset's own scheme.
    package static var systemIsDark: Bool {
        UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    }
}
